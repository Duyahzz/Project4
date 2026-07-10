import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Card } from '../../components/Card'
import { ChatPanel } from '../../components/ChatPanel'
import { Tabs } from '../../components/Tabs'
import { TimetableGrid } from '../../components/TimetableGrid'
import { useAuth } from '../../hooks/useAuth'
import { useData } from '../../hooks/useData'
import { useToast } from '../../hooks/useToast'
import { notificationDetailPath } from '../notificationDetailPath'
import type { AttendanceRecord, AttendanceStatus, Resource } from '../../types'

const STATUS_STYLES: Record<AttendanceStatus, string> = {
  present: 'bg-emerald-100 text-emerald-700',
  absent: 'bg-rose-100 text-rose-700',
  late: 'bg-amber-100 text-amber-700',
  excused: 'bg-slate-100 text-slate-600',
}

export function StudentDashboard() {
  const { currentUser } = useAuth()
  const {
    attendance,
    revisionClasses,
    evaluations,
    notifications,
    chatGroups,
    helplines,
    scores,
    classes,
    timetable,
    users,
    semesters,
  } = useData()
  const { push } = useToast()

  const email = currentUser?.email ?? ''
  const classId = currentUser?.classId ?? ''

  const [timetableSemesterId, setTimetableSemesterId] = useState(() => {
    const today = new Date().toISOString().slice(0, 10)
    return semesters.find((s) => today >= s.startDate && today <= s.endDate)?.id 
      ?? semesters[semesters.length - 1]?.id 
      ?? 'S2-2025'
  })

  // Get class info
  const studentClass = useMemo(
    () => classes.find((c) => c.id === classId),
    [classes, classId],
  )

  // Get homeroom teacher
  const homeroomTeacher = useMemo(
    () => studentClass ? users.find((u) => u.email === studentClass.homeroomTeacher) : undefined,
    [users, studentClass],
  )

  // Student scores
  const studentScores = useMemo(
    () => scores.filter((s) => s.studentEmail === email),
    [scores, email],
  )

  // Calculate average score
  const avgScore = useMemo(() => {
    if (studentScores.length === 0) return null
    const sum = studentScores.reduce((acc, s) => acc + s.scoreReceived, 0)
    return Math.round(sum / studentScores.length)
  }, [studentScores])

  const studentAttendance = useMemo(
    () => attendance.filter((item) => item.studentEmail === email),
    [attendance, email],
  )

  // Calculate attendance rate
  const attendanceRate = useMemo(() => {
    if (studentAttendance.length === 0) return null
    const present = studentAttendance.filter((a) => a.status === 'present' || a.status === 'late').length
    return Math.round((present / studentAttendance.length) * 100)
  }, [studentAttendance])

  const studentEvaluations = useMemo(
    () => evaluations.filter((item) => item.studentEmail === email),
    [evaluations, email],
  )
  const myNotifications = useMemo(
    () =>
      notifications.filter(
        (n) =>
          (n.audience === 'student' && n.target === email) ||
          (n.audience === 'class' && n.target === classId),
      ),
    [notifications, email, classId],
  )
  const studentChatGroup = useMemo(
    () => chatGroups.find((g) => g.classId === classId && g.type === 'student-teacher'),
    [chatGroups, classId],
  )

  // Count weekly timetable slots
  const weeklySlots = useMemo(
    () => timetable.filter((s) => s.classId === classId).length,
    [timetable, classId],
  )

  // Count classmates
  const classmates = useMemo(
    () => users.filter((u) => u.role === 'student' && u.classId === classId && u.email !== email),
    [users, classId, email],
  )

  return (
    <Tabs
      tabs={[
        {
          id: 'overview',
          label: 'Overview',
          content: (
            <div className="space-y-4">
              <Card title={`Welcome, ${currentUser?.fullName ?? 'Student'}!`}>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 text-center">
                  <div className="border border-slate-200 rounded-lg p-3">
                    <p className="text-2xl font-bold text-indigo-600">
                      {(studentClass?.name ?? classId) || '—'}
                    </p>
                    <p className="text-xs text-slate-500 mt-1">Class</p>
                  </div>
                  <div className="border border-slate-200 rounded-lg p-3">
                    <p className="text-2xl font-bold text-emerald-600">
                      {avgScore !== null ? `${avgScore}%` : '—'}
                    </p>
                    <p className="text-xs text-slate-500 mt-1">Avg Score</p>
                  </div>
                  <div className="border border-slate-200 rounded-lg p-3">
                    <p className="text-2xl font-bold text-amber-600">
                      {attendanceRate !== null ? `${attendanceRate}%` : '—'}
                    </p>
                    <p className="text-xs text-slate-500 mt-1">Attendance</p>
                  </div>
                  <div className="border border-slate-200 rounded-lg p-3">
                    <p className="text-2xl font-bold text-slate-600">
                      {studentScores.length}
                    </p>
                    <p className="text-xs text-slate-500 mt-1">Tests Taken</p>
                  </div>
                </div>
              </Card>

              <div className="grid gap-4 lg:grid-cols-2">
                <Card title="Class Info">
                  <dl className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <dt className="text-slate-500">Class</dt>
                      <dd className="font-medium text-slate-800">
                        {(studentClass?.name ?? classId) || 'Not assigned'}
                      </dd>
                    </div>
                    {studentClass && (
                      <>
                        <div className="flex justify-between">
                          <dt className="text-slate-500">Grade</dt>
                          <dd className="font-medium text-slate-800">Grade {studentClass.grade}</dd>
                        </div>
                        <div className="flex justify-between">
                          <dt className="text-slate-500">Academic Year</dt>
                          <dd className="font-medium text-slate-800">{studentClass.year}</dd>
                        </div>
                      </>
                    )}
                    <div className="flex justify-between">
                      <dt className="text-slate-500">Homeroom Teacher</dt>
                      <dd className="font-medium text-slate-800">
                        {homeroomTeacher?.fullName ?? 'Not assigned'}
                      </dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-slate-500">Classmates</dt>
                      <dd className="font-medium text-slate-800">{classmates.length}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-slate-500">Weekly Classes</dt>
                      <dd className="font-medium text-slate-800">{weeklySlots} slots</dd>
                    </div>
                  </dl>
                </Card>

                <Card title="Quick Stats">
                  <dl className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <dt className="text-slate-500">Total Scores</dt>
                      <dd className="font-medium text-slate-800">{studentScores.length}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-slate-500">Attendance Records</dt>
                      <dd className="font-medium text-slate-800">{studentAttendance.length}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-slate-500">Evaluations</dt>
                      <dd className="font-medium text-slate-800">{studentEvaluations.length}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-slate-500">Notifications</dt>
                      <dd className="font-medium text-slate-800">{myNotifications.length}</dd>
                    </div>
                    <div className="flex justify-between">
                      <dt className="text-slate-500">Available Revision Classes</dt>
                      <dd className="font-medium text-slate-800">{revisionClasses.length}</dd>
                    </div>
                  </dl>
                </Card>
              </div>

              {myNotifications.length > 0 && (
                <Card title="Recent Notifications">
                  <ul className="space-y-2">
                    {myNotifications.slice(0, 3).map((n) => (
                      <li key={n.id} className="border border-slate-200 rounded-lg px-3 py-2">
                        <Link
                          to={notificationDetailPath(n.id)}
                          className="font-semibold text-indigo-600 hover:text-indigo-800 hover:underline"
                        >
                          {n.title}
                        </Link>
                        <p className="text-sm text-slate-600 line-clamp-1">{n.body}</p>
                        <p className="text-xs text-slate-400 mt-1">{n.date}</p>
                      </li>
                    ))}
                  </ul>
                </Card>
              )}
            </div>
          ),
        },
        {
          id: 'timetable',
          label: 'Timetable',
          content: (
            <Card title="Weekly Timetable" description={`Class ${studentClass?.name ?? classId}`}>
              <div className="flex items-center gap-3 mb-4">
                <label className="text-sm font-medium text-slate-700 shrink-0">Semester</label>
                <select
                  value={timetableSemesterId}
                  onChange={(e) => setTimetableSemesterId(e.target.value)}
                  className="rounded-md border border-slate-300 px-3 py-1.5 text-sm text-slate-700 bg-white"
                >
                  {semesters.map((s) => (
                    <option key={s.id} value={s.id}>{s.name} ({s.year})</option>
                  ))}
                </select>
              </div>
              <TimetableGrid classId={classId} studentEmail={email} semesterId={timetableSemesterId} />
            </Card>
          ),
        },
        {
          id: 'marks',
          label: 'Marks',
          content: <MarksTab email={email} />,
        },
        {
          id: 'attendance',
          label: 'Attendance',
          content: <AttendanceTab studentAttendance={studentAttendance} classId={classId} />,
        },
        {
          id: 'resources',
          label: 'Resources',
          content: <ResourcesTab classId={classId} />,
        },
        {
          id: 'revision',
          label: 'Revision',
          content: (
            <Card title="Revision Classes" description="Optional out-of-hours classes you can join">
              <ul className="space-y-2">
                {revisionClasses.map((revision) => (
                  <li
                    key={revision.id}
                    className="flex items-center justify-between gap-3 border border-slate-200 rounded-lg px-3 py-2"
                  >
                    <div className="flex flex-col">
                      <span className="font-semibold text-slate-900">{revision.topic}</span>
                      <span className="text-xs text-slate-500">
                        {revision.subject} · {revision.dateTime.replace('T', ' ')} ·{' '}
                        {revision.teacher}
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() => push('success', `Enrolled in "${revision.topic}".`)}
                      className="text-sm font-semibold text-indigo-600 hover:underline"
                    >
                      Enroll
                    </button>
                  </li>
                ))}
              </ul>
            </Card>
          ),
        },
        {
          id: 'ai',
          label: 'AI Path',
          content: (
            <Card
              title="AI-Suggested Learning Path"
              description="Generated from your teachers' detailed test evaluations"
            >
              {studentEvaluations.length === 0 ? (
                <p className="text-sm text-slate-500">No evaluations yet.</p>
              ) : (
                <ul className="space-y-3">
                  {studentEvaluations.map((evaluation) => (
                    <li
                      key={evaluation.id}
                      className="border border-slate-200 rounded-lg px-3 py-3"
                    >
                      <p className="font-semibold text-slate-900">
                        {evaluation.subject} · {evaluation.testId}
                      </p>
                      <p className="text-sm text-emerald-700 mt-1">
                        <span className="font-semibold">Strengths:</span> {evaluation.strengths}
                      </p>
                      <p className="text-sm text-rose-700">
                        <span className="font-semibold">To improve:</span> {evaluation.weaknesses}
                      </p>
                      <p className="text-sm text-indigo-700 mt-1 bg-indigo-50 rounded-md px-2 py-1">
                        {evaluation.suggestedPath}
                      </p>
                    </li>
                  ))}
                </ul>
              )}
            </Card>
          ),
        },
        {
          id: 'notifications',
          label: 'Notifications',
          content: (
            <Card title="Notifications">
              {myNotifications.length === 0 ? (
                <p className="text-sm text-slate-500">No notifications.</p>
              ) : (
                <ul className="space-y-2">
                  {myNotifications.map((n) => (
                    <li key={n.id} className="border border-slate-200 rounded-lg px-3 py-2">
                      <Link
                        to={notificationDetailPath(n.id)}
                        className="font-semibold text-indigo-600 hover:text-indigo-800 hover:underline"
                      >
                        {n.title}
                      </Link>
                      <p className="text-sm text-slate-600">{n.body}</p>
                      <p className="text-xs text-slate-400 mt-1">
                        {n.date} · {n.sender}
                      </p>
                    </li>
                  ))}
                </ul>
              )}
            </Card>
          ),
        },
        {
          id: 'chat',
          label: 'Class Chat',
          content: (
            <Card title="Class Chat Group" description="Students & teachers of your class">
              {studentChatGroup ? (
                <ChatPanel groupId={studentChatGroup.id} />
              ) : (
                <p className="text-sm text-slate-500">No chat group for your class yet.</p>
              )}
            </Card>
          ),
        },
        {
          id: 'helplines',
          label: 'Helplines',
          content: (
            <Card title="Helplines">
              <ul className="grid sm:grid-cols-3 gap-3">
                {helplines.map((helpline) => (
                  <li
                    key={helpline.phone}
                    className="border border-slate-200 rounded-lg px-3 py-2"
                  >
                    <p className="font-semibold text-slate-900">{helpline.label}</p>
                    <p className="text-sm text-slate-600">{helpline.phone}</p>
                  </li>
                ))}
              </ul>
            </Card>
          ),
        },
        {
          id: 'grade-progress',
          label: 'Grade Progress',
          content: (
            <div className="space-y-4">
              <Card title="Current Grade Status">
                <div className="grid sm:grid-cols-3 gap-4">
                  <div className="border-2 border-indigo-600 rounded-lg p-4 text-center">
                    <p className="text-xs text-slate-500 uppercase tracking-wide mb-1">Current Grade</p>
                    <p className="text-4xl font-bold text-indigo-600">{currentUser?.grade ?? '—'}</p>
                  </div>
                  <div className="border border-slate-200 rounded-lg p-4 text-center">
                    <p className="text-xs text-slate-500 uppercase tracking-wide mb-1">Class</p>
                    <p className="text-2xl font-semibold text-slate-900">{studentClass?.name ?? '—'}</p>
                  </div>
                  <div className="border border-slate-200 rounded-lg p-4 text-center">
                    <p className="text-xs text-slate-500 uppercase tracking-wide mb-1">Academic Year</p>
                    <p className="text-2xl font-semibold text-slate-900">{studentClass?.year ?? '—'}</p>
                  </div>
                </div>
              </Card>

              <Card title="Grade Progression History">
                <div className="space-y-3">
                  <div className="flex items-center gap-3">
                    <div className="flex flex-col items-center">
                      <div className="w-10 h-10 rounded-full bg-emerald-600 text-white flex items-center justify-center font-semibold text-sm">
                        10
                      </div>
                      <div className="w-0.5 h-8 bg-slate-200 mt-1"></div>
                    </div>
                    <div>
                      <p className="font-semibold text-slate-900">Grade 10 - Entry</p>
                      <p className="text-sm text-slate-600">Initial enrollment in secondary school</p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <div className="flex flex-col items-center">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold text-sm ${ currentUser?.grade && currentUser.grade >= 11 ? 'bg-indigo-600 text-white' : 'bg-slate-200 text-slate-400'}`}>
                        11
                      </div>
                      <div className="w-0.5 h-8 bg-slate-200 mt-1"></div>
                    </div>
                    <div>
                      <p className={`font-semibold ${ currentUser?.grade && currentUser.grade >= 11 ? 'text-slate-900' : 'text-slate-400'}`}>
                        Grade 11 - Promotion
                      </p>
                      <p className={`text-sm ${ currentUser?.grade && currentUser.grade >= 11 ? 'text-slate-600' : 'text-slate-400'}`}>
                        {currentUser?.grade && currentUser.grade >= 11 ? 'Completed' : 'Not yet reached'}
                      </p>
                    </div>
                  </div>

                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold text-sm ${ currentUser?.grade === 12 ? 'bg-amber-600 text-white' : 'bg-slate-200 text-slate-400'}`}>
                      12
                    </div>
                    <div>
                      <p className={`font-semibold ${ currentUser?.grade === 12 ? 'text-slate-900' : 'text-slate-400'}`}>
                        Grade 12 - Final Year
                      </p>
                      <p className={`text-sm ${ currentUser?.grade === 12 ? 'text-slate-600' : 'text-slate-400'}`}>
                        {currentUser?.grade === 12 ? 'Currently in final year' : 'Not yet reached'}
                      </p>
                    </div>
                  </div>
                </div>
              </Card>

              <Card title="Key Milestones">
                <ul className="space-y-2 text-sm">
                  <li className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                    <span className="text-emerald-600 font-bold mt-0.5">✓</span>
                    <span>Enrolled as Grade {currentUser?.grade ?? 'N/A'} student</span>
                  </li>
                  {currentUser?.grade && currentUser.grade >= 11 && (
                    <li className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                      <span className="text-indigo-600 font-bold mt-0.5">✓</span>
                      <span>Promoted to Grade 11</span>
                    </li>
                  )}
                  {currentUser?.grade === 12 && (
                    <li className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                      <span className="text-amber-600 font-bold mt-0.5">✓</span>
                      <span>Promoted to Grade 12 - Final Year</span>
                    </li>
                  )}
                </ul>
              </Card>
            </div>
          ),
        },
      ]}
    />
  )
}

// ── Marks Tab ────────────────────────────────────────────────────────────────

function scoreStyle(s: number) {
  if (s >= 90) return 'bg-emerald-100 text-emerald-700'
  if (s >= 70) return 'bg-indigo-100 text-indigo-700'
  if (s >= 50) return 'bg-amber-100 text-amber-700'
  return 'bg-rose-100 text-rose-700'
}

export function MarksTab({ email }: { email: string }) {
  const { scores, evaluations, semesters } = useData()

  const [selectedSemesterId, setSelectedSemesterId] = useState(() => {
    const today = new Date().toISOString().slice(0, 10)
    return semesters.find((s) => today >= s.startDate && today <= s.endDate)?.id ?? ''
  })
  const [selectedKey, setSelectedKey] = useState<string | null>(null)

  const studentScores = useMemo(
    () => scores.filter((s) => s.studentEmail === email),
    [scores, email],
  )

  const filteredScores = useMemo(() => {
    if (!selectedSemesterId) return studentScores
    const sem = semesters.find((s) => s.id === selectedSemesterId)
    if (!sem) return studentScores
    return studentScores.filter((s) => s.date >= sem.startDate && s.date <= sem.endDate)
  }, [studentScores, semesters, selectedSemesterId])

  const grouped = useMemo(() => {
    const map = new Map<string, typeof filteredScores>()
    for (const s of filteredScores) {
      if (!map.has(s.subject)) map.set(s.subject, [])
      map.get(s.subject)!.push(s)
    }
    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b))
  }, [filteredScores])

  const selectedEval = useMemo(() => {
    if (!selectedKey) return null
    const [subject, testId] = selectedKey.split(':')
    return (
      evaluations.find(
        (e) => e.studentEmail === email && e.subject === subject && e.testId === testId,
      ) ?? null
    )
  }, [evaluations, email, selectedKey])

  return (
    <div className="space-y-4">
      {/* Semester selector */}
      <div className="flex items-center gap-3">
        <label className="text-sm font-medium text-slate-700 shrink-0">Semester</label>
        <select
          value={selectedSemesterId}
          onChange={(e) => { setSelectedSemesterId(e.target.value); setSelectedKey(null) }}
          className="rounded-md border border-slate-300 px-3 py-1.5 text-sm text-slate-700 bg-white"
        >
          <option value="">All semesters</option>
          {semesters.map((s) => (
            <option key={s.id} value={s.id}>{s.name} ({s.year})</option>
          ))}
        </select>
      </div>

      {filteredScores.length === 0 ? (
        <p className="text-sm text-slate-500">No scores recorded for this period.</p>
      ) : (
        grouped.map(([subject, subjectScores]) => {
          const avg = Math.round(
            subjectScores.reduce((sum, s) => sum + s.scoreReceived, 0) / subjectScores.length,
          )
          return (
            <Card
              key={subject}
              title={subject}
              description={`${subjectScores.length} test${subjectScores.length > 1 ? 's' : ''} · Average: ${avg}`}
            >
              <div className="overflow-x-auto">
                <table className="min-w-full text-sm">
                  <thead>
                    <tr className="text-left text-slate-500 border-b border-slate-200 text-xs">
                      <th className="py-2 pr-3">Test ID</th>
                      <th className="py-2 pr-3">Description</th>
                      <th className="py-2 pr-3">Date</th>
                      <th className="py-2 pr-3 text-center">Score</th>
                      <th className="py-2" />
                    </tr>
                  </thead>
                  <tbody>
                    {subjectScores.map((item) => {
                      const key = `${subject}:${item.testId}`
                      const isSelected = selectedKey === key
                      const hasEval = evaluations.some(
                        (e) => e.studentEmail === email && e.subject === subject && e.testId === item.testId,
                      )
                      return (
                        <tr
                          key={item.id}
                          className={`border-b border-slate-100 ${isSelected ? 'bg-indigo-50' : ''}`}
                        >
                          <td className="py-2 pr-3 font-mono text-xs text-slate-600">{item.testId}</td>
                          <td className="py-2 pr-3">{item.description}</td>
                          <td className="py-2 pr-3 text-slate-500 whitespace-nowrap">{item.date}</td>
                          <td className="py-2 pr-3 text-center">
                            <span className={`inline-flex rounded-full px-2 py-0.5 text-xs font-bold ${scoreStyle(item.scoreReceived)}`}>
                              {item.scoreReceived}
                            </span>
                          </td>
                          <td className="py-2 text-right">
                            {hasEval && (
                              <button
                                type="button"
                                onClick={() => setSelectedKey(isSelected ? null : key)}
                                className={`text-xs font-medium px-2 py-1 rounded border transition-colors ${
                                  isSelected
                                    ? 'bg-indigo-600 text-white border-indigo-600'
                                    : 'text-indigo-600 border-indigo-200 hover:bg-indigo-50'
                                }`}
                              >
                                {isSelected ? 'Hide' : '📋 Evaluation'}
                              </button>
                            )}
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>

              {/* Inline evaluation detail */}
              {selectedKey?.startsWith(subject + ':') && selectedEval && (
                <div className="mt-3 rounded-lg border border-indigo-100 bg-indigo-50/60 p-4 space-y-3 text-sm">
                  <div className="flex items-center justify-between">
                    <p className="font-semibold text-indigo-800">Teacher Evaluation — {selectedEval.testId}</p>
                    <p className="text-xs text-slate-500">by {selectedEval.teacher}</p>
                  </div>
                  <div className="grid sm:grid-cols-2 gap-3">
                    <div>
                      <p className="text-xs font-semibold text-emerald-700 uppercase mb-1">✅ Strengths</p>
                      <p className="text-slate-700">{selectedEval.strengths}</p>
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-rose-700 uppercase mb-1">⚠️ Weaknesses</p>
                      <p className="text-slate-700">{selectedEval.weaknesses}</p>
                    </div>
                  </div>
                  <div>
                    <p className="text-xs font-semibold text-indigo-700 uppercase mb-1">🤖 Suggested Learning Path</p>
                    <p className="text-slate-700">{selectedEval.suggestedPath}</p>
                  </div>
                </div>
              )}
            </Card>
          )
        })
      )}
    </div>
  )
}

// ── Attendance Tab ────────────────────────────────────────────────────────────

const DAYS_ATT = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'] as const
const ALL_PERIODS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

function attGetMonday(d: Date): Date {
  const day = d.getDay()
  const m = new Date(d)
  m.setDate(m.getDate() + (day === 0 ? -6 : 1 - day))
  m.setHours(0, 0, 0, 0)
  return m
}

function attDateStr(d: Date): string {
  // Use local date methods to match TimetableGrid's localDateStr (avoids timezone issues)
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export function AttendanceTab({
  studentAttendance,
  classId,
}: {
  studentAttendance: AttendanceRecord[]
  classId: string
}) {
  const { timetable, semesters } = useData()
  const [selectedSemesterId, setSelectedSemesterId] = useState(() => {
    const today = new Date().toISOString().slice(0, 10)
    return semesters.find((s) => today >= s.startDate && today <= s.endDate)?.id 
      ?? semesters[semesters.length - 1]?.id 
      ?? 'S2-2025'
  })
  
  const [weekStart, setWeekStart] = useState(() => attGetMonday(new Date()))

  useEffect(() => {
    const sem = semesters.find((s) => s.id === selectedSemesterId)
    if (!sem) return

    const today = attDateStr(new Date())
    if (today >= sem.startDate && today <= sem.endDate) {
      setWeekStart(attGetMonday(new Date()))
    } else {
      setWeekStart(attGetMonday(new Date(sem.startDate + 'T00:00:00')))
    }
  }, [selectedSemesterId, semesters])

  const shiftWeek = (n: number) =>
    setWeekStart((d) => { const nd = new Date(d); nd.setDate(nd.getDate() + n * 7); return nd })

  // Columns: Mon–Sat of current week
  const weekDays = DAYS_ATT.map((day, i) => {
    const d = new Date(weekStart)
    d.setDate(d.getDate() + i)
    return {
      day,
      dateStr: attDateStr(d),
      label: d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }),
    }
  })

  const todayStr = attDateStr(new Date())

  // Get student's class timetable slots for the selected semester (falls back to Semester 1 if Semester 2 is unseeded)
  const classTimetableSlots = useMemo(() => {
    const slots = timetable.filter(
      (slot) => slot.classId === classId && slot.semesterId === selectedSemesterId
    )
    if (slots.length > 0) return slots

    const firstSem = semesters[0]?.id ?? 'S1-2025'
    return timetable.filter(
      (slot) => slot.classId === classId && slot.semesterId === firstSem
    )
  }, [timetable, classId, selectedSemesterId, semesters])

  const activeSemester = useMemo(() => {
    return semesters.find((s) => s.id === selectedSemesterId)
  }, [semesters, selectedSemesterId])

  // Filter attendance records by selected semester date range
  const filteredAttendance = useMemo(() => {
    if (!activeSemester) return studentAttendance
    return studentAttendance.filter(
      (rec) => rec.date >= activeSemester.startDate && rec.date <= activeSemester.endDate
    )
  }, [studentAttendance, activeSemester])

  // date → period → record
  const lookup = useMemo(() => {
    const map = new Map<string, Map<number, AttendanceRecord>>()
    for (const rec of filteredAttendance) {
      if (!map.has(rec.date)) map.set(rec.date, new Map())
      map.get(rec.date)!.set(rec.period, rec)
    }
    return map
  }, [filteredAttendance])

  // Show periods that have any record or are in the student's timetable
  const activePeriods = useMemo(() => {
    const pSet = new Set([
      ...filteredAttendance.map((a) => a.period),
      ...classTimetableSlots.map((s) => s.period),
    ])
    return ALL_PERIODS.filter((p) => pSet.has(p))
  }, [filteredAttendance, classTimetableSlots])

  // All-time summary counts (also filtered by semester!)
  const totals = useMemo(() => {
    const counts: Record<AttendanceStatus, number> = { present: 0, absent: 0, late: 0, excused: 0 }
    for (const rec of filteredAttendance) counts[rec.status]++
    return counts
  }, [filteredAttendance])

  const weekHasRecordsOrSlots = useMemo(() => {
    const hasRecords = weekDays.some(({ dateStr }) => lookup.has(dateStr))
    const hasSlots = classTimetableSlots.length > 0
    return hasRecords || hasSlots
  }, [weekDays, lookup, classTimetableSlots])

  // Dropdown: weeks of the selected semester
  const weekOptions = useMemo(() => {
    const sem = semesters.find((s) => s.id === selectedSemesterId)
    if (!sem) return []

    const startMon = attGetMonday(new Date(sem.startDate + 'T00:00:00'))
    const endMon = attGetMonday(new Date(sem.endDate + 'T00:00:00'))
    const options = []
    let curr = new Date(startMon)

    while (curr <= endMon) {
      const sat = new Date(curr)
      sat.setDate(sat.getDate() + 5)
      const fmt = (d: Date) => d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' })
      options.push({
        value: attDateStr(curr),
        label: `${fmt(curr)} – ${fmt(sat)}`,
      })
      curr.setDate(curr.getDate() + 7)
    }
    return options
  }, [selectedSemesterId, semesters])

  const isFirstWeek = useMemo(() => {
    return weekOptions.length > 0 && attDateStr(weekStart) === weekOptions[0].value
  }, [weekOptions, weekStart])

  const isLastWeek = useMemo(() => {
    return weekOptions.length > 0 && attDateStr(weekStart) === weekOptions[weekOptions.length - 1].value
  }, [weekOptions, weekStart])

  return (
    <div className="space-y-4">
      {/* Semester Selector */}
      <div className="flex items-center gap-3">
        <label className="text-sm font-medium text-slate-700 shrink-0">Semester</label>
        <select
          value={selectedSemesterId}
          onChange={(e) => setSelectedSemesterId(e.target.value)}
          className="rounded-md border border-slate-300 px-3 py-1.5 text-sm text-slate-700 bg-white"
        >
          {semesters.map((s) => (
            <option key={s.id} value={s.id}>{s.name} ({s.year})</option>
          ))}
        </select>
      </div>

      {/* All-time summary */}
      <div className="grid grid-cols-4 gap-3">
        {(Object.entries(totals) as [AttendanceStatus, number][]).map(([status, count]) => (
          <div key={status} className={`rounded-lg p-3 text-center ${STATUS_STYLES[status]}`}>
            <p className="text-2xl font-bold">{count}</p>
            <p className="text-xs capitalize mt-0.5">{status}</p>
          </div>
        ))}
      </div>

      {/* Week navigator */}
      <div className="flex items-center gap-2 flex-wrap">
        <button
          type="button"
          onClick={() => shiftWeek(-1)}
          disabled={isFirstWeek}
          className={`px-3 py-1.5 rounded border border-slate-300 text-sm ${
            isFirstWeek
              ? 'opacity-50 cursor-not-allowed text-slate-400'
              : 'hover:bg-slate-50 text-slate-700'
          }`}
        >
          ←
        </button>
        <select
          value={attDateStr(weekStart)}
          onChange={(e) => setWeekStart(new Date(e.target.value + 'T00:00:00'))}
          className="rounded-md border border-slate-300 px-3 py-1.5 text-sm text-slate-700 bg-white min-w-[200px]"
        >
          {weekOptions.map((opt) => (
            <option key={opt.value} value={opt.value}>{opt.label}</option>
          ))}
        </select>
        <button
          type="button"
          onClick={() => shiftWeek(1)}
          disabled={isLastWeek}
          className={`px-3 py-1.5 rounded border border-slate-300 text-sm ${
            isLastWeek
              ? 'opacity-50 cursor-not-allowed text-slate-400'
              : 'hover:bg-slate-50 text-slate-700'
          }`}
        >
          →
        </button>
        <button
          type="button"
          onClick={() => {
            const sem = semesters.find((s) => s.id === selectedSemesterId)
            if (!sem) return
            const todayVal = attDateStr(new Date())
            if (todayVal >= sem.startDate && todayVal <= sem.endDate) {
              setWeekStart(attGetMonday(new Date()))
            } else {
              setWeekStart(attGetMonday(new Date(sem.startDate + 'T00:00:00')))
            }
          }}
          className="ml-1 px-3 py-1.5 rounded border border-slate-300 text-sm text-indigo-600 hover:bg-indigo-50"
        >
          Today
        </button>
      </div>

      {/* Grid */}
      {activePeriods.length === 0 ? (
        <p className="text-sm text-slate-500">No attendance or timetable recorded yet.</p>
      ) : (
        <div className="overflow-x-auto rounded-lg border border-slate-200">
          <table className="min-w-full text-sm border-collapse">
            <thead>
              <tr className="bg-slate-50 border-b border-slate-200">
                <th className="py-2 px-3 text-left text-xs font-semibold text-slate-500 w-16">
                  Period
                </th>
                {weekDays.map(({ day, dateStr, label }) => (
                  <th
                    key={day}
                    className={`py-2 px-3 text-center text-xs font-semibold min-w-[100px] ${
                      dateStr === todayStr
                        ? 'bg-indigo-50 text-indigo-700'
                        : 'text-slate-500'
                    }`}
                  >
                    <span className="block">{day}</span>
                    <span className="block font-normal">{label}</span>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {activePeriods.map((period) => (
                <tr key={period} className="border-b border-slate-100 last:border-0">
                  <td className="py-2 px-3 text-xs font-semibold text-slate-500">
                    P{period}
                  </td>
                  {weekDays.map(({ day, dateStr }) => {
                    const rec = lookup.get(dateStr)?.get(period)
                    const slot = classTimetableSlots.find((s) => s.day === day && s.period === period)
                    return (
                      <td
                        key={day}
                        className={`py-2 px-3 text-center ${
                          dateStr === todayStr ? 'bg-indigo-50/40' : ''
                        }`}
                      >
                        {rec ? (
                          <div className="flex flex-col items-center gap-1">
                            <span className="text-xs text-slate-600 font-medium leading-tight">
                              {rec.subject}
                            </span>
                            <span
                              className={`inline-flex rounded-full px-2 py-0.5 text-xs font-semibold capitalize ${STATUS_STYLES[rec.status]}`}
                            >
                              {rec.status}
                            </span>
                            {rec.note ? (
                              <span className="text-[10px] text-slate-500 italic max-w-[120px] truncate" title={rec.note}>
                                Note: {rec.note}
                              </span>
                            ) : null}
                          </div>
                        ) : slot ? (
                          <div className="flex flex-col items-center gap-1">
                            <span className="text-xs text-slate-600 font-medium leading-tight">
                              {slot.subject}
                            </span>
                            <span className="inline-flex rounded-full px-2 py-0.5 text-xs font-semibold bg-slate-100 text-slate-400">
                              Not Marked
                            </span>
                          </div>
                        ) : (
                          <span className="text-slate-300">—</span>
                        )}
                      </td>
                    )
                  })}
                </tr>
              ))}
              {!weekHasRecordsOrSlots && (
                <tr>
                  <td
                    colSpan={7}
                    className="py-6 text-center text-sm text-slate-400"
                  >
                    No scheduled classes or attendance records for this week.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

// ── Resources Tab ─────────────────────────────────────────────────────────────

const TYPE_ICON: Record<Resource['type'], string> = {
  video: '🎬',
  document: '📄',
  'external-link': '🔗',
}

function ResourcesTab({ classId }: { classId: string }) {
  const { resources, timetable } = useData()
  const [selectedSubject, setSelectedSubject] = useState<string | null>(null)

  const subjects = useMemo(() => {
    const seen = new Set(timetable.filter((s) => s.classId === classId).map((s) => s.subject))
    return Array.from(seen).sort()
  }, [timetable, classId])

  const classResources = useMemo(
    () => resources.filter((r) => r.classId === classId),
    [resources, classId],
  )

  const countBySubject = useMemo(() => {
    const map = new Map<string, number>()
    for (const r of classResources) map.set(r.subject, (map.get(r.subject) ?? 0) + 1)
    return map
  }, [classResources])

  const active = selectedSubject ?? subjects[0] ?? null

  const subjectResources = useMemo(
    () => classResources.filter((r) => r.subject === active),
    [classResources, active],
  )

  if (subjects.length === 0) {
    return <p className="text-sm text-slate-500">No subjects found for your class.</p>
  }

  return (
    <div className="flex gap-4 min-h-[260px]">
      {/* Subject sidebar */}
      <nav className="w-44 shrink-0 space-y-1">
        {subjects.map((subject) => {
          const count = countBySubject.get(subject) ?? 0
          const isActive = active === subject
          return (
            <button
              key={subject}
              type="button"
              onClick={() => setSelectedSubject(subject)}
              className={`w-full text-left px-3 py-2 rounded-lg text-sm flex items-center justify-between gap-2 transition-colors ${
                isActive
                  ? 'bg-indigo-600 text-white'
                  : 'text-slate-700 hover:bg-slate-100'
              }`}
            >
              <span className="truncate">{subject}</span>
              {count > 0 && (
                <span
                  className={`shrink-0 rounded-full px-1.5 py-0.5 text-xs font-semibold ${
                    isActive ? 'bg-white/25 text-white' : 'bg-slate-200 text-slate-600'
                  }`}
                >
                  {count}
                </span>
              )}
            </button>
          )
        })}
      </nav>

      {/* Divider */}
      <div className="w-px bg-slate-200 shrink-0" />

      {/* Resource list */}
      <div className="flex-1 min-w-0">
        {subjectResources.length === 0 ? (
          <p className="text-sm text-slate-400 mt-2">No resources for {active} yet.</p>
        ) : (
          <ul className="space-y-2">
            {subjectResources.map((resource) => (
              <li
                key={resource.id}
                className="flex items-start justify-between gap-3 border border-slate-200 rounded-lg px-3 py-2.5"
              >
                <div className="flex items-start gap-2 min-w-0">
                  <span className="text-base mt-0.5 shrink-0">{TYPE_ICON[resource.type]}</span>
                  <div className="min-w-0">
                    <a
                      href={resource.url}
                      target="_blank"
                      rel="noreferrer"
                      className="text-indigo-600 font-semibold hover:underline break-words"
                    >
                      {resource.title}
                    </a>
                    <p className="text-xs text-slate-500 mt-0.5">
                      Added by {resource.addedBy}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-1.5 shrink-0">
                  {resource.system === 'revision' && (
                    <span className="rounded-full bg-amber-100 text-amber-700 px-2 py-0.5 text-xs font-semibold">
                      revision
                    </span>
                  )}
                  <span className="rounded-full bg-slate-100 text-slate-600 px-2 py-0.5 text-xs font-semibold capitalize">
                    {resource.type.replace('-', ' ')}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
