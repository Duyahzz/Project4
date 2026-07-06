import { useEffect, useMemo, useState } from 'react'
import { useData } from '../hooks/useData'
import type { AttendanceStatus, DayOfWeek, TimetableSlot } from '../types'

const DAYS: DayOfWeek[] = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const DAY_OFFSET: Record<DayOfWeek, number> = { Mon: 0, Tue: 1, Wed: 2, Thu: 3, Fri: 4, Sat: 5 }

const PERIOD_TIME: Record<number, string> = {
  1: '07:30–08:15',
  2: '08:25–09:10',
  3: '09:20–10:05',
  4: '10:15–11:00',
  5: '11:10–11:55',
  6: '13:00–13:45',
  7: '13:50–14:35',
  8: '14:40–15:25',
  9: '15:30–16:15',
  10: '16:20–17:05',
}

const ATTENDANCE_STYLES: Record<AttendanceStatus, { bg: string; text: string; label: string }> = {
  present: { bg: 'bg-emerald-100', text: 'text-emerald-700', label: 'Present' },
  absent: { bg: 'bg-rose-100', text: 'text-rose-700', label: 'Absent' },
  late: { bg: 'bg-amber-100', text: 'text-amber-700', label: 'Late' },
  excused: { bg: 'bg-slate-100', text: 'text-slate-600', label: 'Excused' },
}

function getMonday(date: Date): Date {
  const d = new Date(date)
  const day = d.getDay()
  d.setDate(d.getDate() - day + (day === 0 ? -6 : 1))
  d.setHours(0, 0, 0, 0)
  return d
}

function localDateStr(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

interface TimetableGridProps {
  classId: string
  /** Filter to a training system; omit to show all. */
  system?: TimetableSlot['system']
  /** Student email to show attendance status for (optional - only for student view). */
  studentEmail?: string
  semesterId?: string
}

export function TimetableGrid({ classId, system, studentEmail, semesterId }: TimetableGridProps) {
  const { timetable, attendance, semesters } = useData()
  const [weekStart, setWeekStart] = useState(() => getMonday(new Date()))

  const today = localDateStr(new Date())

  useEffect(() => {
    if (!semesterId) return
    const sem = semesters.find((s) => s.id === semesterId)
    if (!sem) return

    const todayVal = localDateStr(new Date())
    if (todayVal >= sem.startDate && todayVal <= sem.endDate) {
      setWeekStart(getMonday(new Date()))
    } else {
      setWeekStart(getMonday(new Date(sem.startDate + 'T00:00:00')))
    }
  }, [semesterId, semesters])

  const slots = useMemo(
    () => {
      const filtered = timetable.filter(
        (slot) =>
          slot.classId === classId &&
          (system ? slot.system === system : true) &&
          (semesterId ? slot.semesterId === semesterId : true),
      )
      if (filtered.length > 0 || !semesterId) return filtered

      // Fallback to Semester 1 if active semester has no slots
      const firstSem = semesters[0]?.id ?? 'S1-2025'
      return timetable.filter(
        (slot) =>
          slot.classId === classId &&
          (system ? slot.system === system : true) &&
          slot.semesterId === firstSem,
      )
    },
    [timetable, classId, system, semesterId, semesters],
  )

  const periods = useMemo(() => {
    const set = new Set<number>(slots.map((slot) => slot.period))
    return Array.from(set).sort((a, b) => a - b)
  }, [slots])

  const dateForDay = (day: DayOfWeek): string => {
    const d = new Date(weekStart)
    d.setDate(d.getDate() + DAY_OFFSET[day])
    return localDateStr(d)
  }

  const shiftWeek = (n: number) =>
    setWeekStart((d) => { const nd = new Date(d); nd.setDate(nd.getDate() + n * 7); return nd })

  const isCurrentWeek = localDateStr(getMonday(new Date())) === localDateStr(weekStart)

  // Dropdown: weeks of the selected semester, or fallback to +- 8 weeks if no semesterId
  const weekOptions = useMemo(() => {
    if (!semesterId) {
      const base = getMonday(new Date())
      return Array.from({ length: 17 }, (_, i) => {
        const mon = new Date(base)
        mon.setDate(mon.getDate() + (i - 8) * 7)
        const sat = new Date(mon); sat.setDate(sat.getDate() + 5)
        const fmt = (d: Date) => d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' })
        return { value: localDateStr(mon), label: `${fmt(mon)} – ${fmt(sat)}` }
      })
    }

    const sem = semesters.find((s) => s.id === semesterId)
    if (!sem) return []

    const startMon = getMonday(new Date(sem.startDate + 'T00:00:00'))
    const endMon = getMonday(new Date(sem.endDate + 'T00:00:00'))
    const options = []
    let curr = new Date(startMon)

    while (curr <= endMon) {
      const sat = new Date(curr)
      sat.setDate(sat.getDate() + 5)
      const fmt = (d: Date) => d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' })
      options.push({
        value: localDateStr(curr),
        label: `${fmt(curr)} – ${fmt(sat)}`,
      })
      curr.setDate(curr.getDate() + 7)
    }
    return options
  }, [semesterId, semesters])

  if (slots.length === 0) {
    return <p className="text-sm text-slate-500">No timetable available for this class.</p>
  }

  const lookup = (day: DayOfWeek, period: number) =>
    slots.find((slot) => slot.day === day && slot.period === period)

  // Lookup attendance for a specific date/period/subject
  const lookupAttendance = (date: string, period: number, subject: string) => {
    if (!studentEmail) return undefined
    return attendance.find(
      (a) =>
        a.studentEmail === studentEmail &&
        a.date === date &&
        a.period === period &&
        a.subject === subject,
    )
  }

  const isFirstWeek = useMemo(() => {
    return weekOptions.length > 0 && localDateStr(weekStart) === weekOptions[0].value
  }, [weekOptions, weekStart])

  const isLastWeek = useMemo(() => {
    return weekOptions.length > 0 && localDateStr(weekStart) === weekOptions[weekOptions.length - 1].value
  }, [weekOptions, weekStart])

  return (
    <div className="space-y-3">
      {/* Week navigator */}
      <div className="flex items-center gap-2">
        <button
          onClick={() => shiftWeek(-1)}
          disabled={isFirstWeek}
          className={`text-sm font-medium px-2 py-1 rounded border border-slate-200 ${
            isFirstWeek
              ? 'text-slate-300 cursor-not-allowed'
              : 'text-indigo-600 hover:text-indigo-800 hover:bg-indigo-50'
          }`}
        >←</button>
        <select
          value={localDateStr(weekStart)}
          onChange={(e) => setWeekStart(new Date(e.target.value + 'T00:00:00'))}
          className="flex-1 rounded-md border border-slate-300 px-3 py-1 text-sm text-slate-700 bg-white"
        >
          {weekOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>{opt.label}</option>
          ))}
        </select>
        {!isCurrentWeek && (
          <button
            onClick={() => setWeekStart(getMonday(new Date()))}
            className="text-xs text-indigo-600 hover:underline px-2 shrink-0"
          >Today</button>
        )}
        <button
          onClick={() => shiftWeek(1)}
          disabled={isLastWeek}
          className={`text-sm font-medium px-2 py-1 rounded border border-slate-200 ${
            isLastWeek
              ? 'text-slate-300 cursor-not-allowed'
              : 'text-indigo-600 hover:text-indigo-800 hover:bg-indigo-50'
          }`}
        >→</button>
      </div>

      {/* Grid */}
      <div className="overflow-x-auto">
        <table className="min-w-full text-sm border-collapse">
          <thead>
            <tr className="text-left text-slate-500">
              <th className="py-2 px-3 border-b border-slate-200 text-xs">Period</th>
              {DAYS.map((day) => {
                const date = dateForDay(day)
                const isToday = date === today
                return (
                  <th
                    key={day}
                    className={`py-2 px-3 border-b border-slate-200 text-center ${isToday ? 'bg-indigo-50' : ''}`}
                  >
                    <span className={`block text-xs font-semibold ${isToday ? 'text-indigo-700' : 'text-slate-600'}`}>{day}</span>
                    <span className={`block text-xs ${isToday ? 'text-indigo-500' : 'text-slate-400'}`}>
                      {new Date(date + 'T00:00:00').toLocaleDateString('en-GB', { day: '2-digit', month: 'short' })}
                    </span>
                  </th>
                )
              })}
            </tr>
          </thead>
          <tbody>
            {periods.map((period) => (
              <tr key={period} className="align-top">
                <td className="py-2 px-3 border-b border-slate-100">
                  <span className="font-semibold text-slate-700 block">P{period}</span>
                  {PERIOD_TIME[period] && (
                    <span className="text-xs text-slate-400">{PERIOD_TIME[period]}</span>
                  )}
                </td>
                {DAYS.map((day) => {
                  const slot = lookup(day, period)
                  const isToday = dateForDay(day) === today
                  const date = dateForDay(day)
                  const attendanceRecord = slot ? lookupAttendance(date, period, slot.subject) : undefined
                  const attendanceStyle = attendanceRecord ? ATTENDANCE_STYLES[attendanceRecord.status] : undefined
                  return (
                    <td key={day} className={`py-2 px-3 border-b border-slate-100 ${isToday ? 'bg-indigo-50/40' : ''}`}>
                      {slot ? (
                        <div className={`rounded-md px-2 py-1 ${
                          slot.system === 'revision'
                            ? 'bg-amber-50 border border-amber-200'
                            : 'bg-indigo-50 border border-indigo-100'
                        }`}>
                          <p className="font-semibold text-slate-800">{slot.subject}</p>
                          <p className="text-xs text-slate-500">{slot.teacher} · {slot.room}</p>
                          {attendanceStyle && (
                            <span className={`inline-block mt-1 text-xs font-medium px-1.5 py-0.5 rounded ${attendanceStyle.bg} ${attendanceStyle.text}`}>
                              {attendanceStyle.label}
                            </span>
                          )}
                        </div>
                      ) : (
                        <span className="text-slate-300">—</span>
                      )}
                    </td>
                  )
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
