import { useMemo, useState } from 'react'
import { Link, useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { Card } from '../components/Card'
import { FormField } from '../components/FormField'
import { useData } from '../hooks/useData'
import { useToast } from '../hooks/useToast'
import { classDetailPath } from './classDetailPath'
import { userDetailPath } from './userDetailPath'
import { enrollStudentInClass, removeStudentFromClass } from '../services/api'
import type { Exam, Grade, SchoolClass, ScoreDetail, User } from '../types'

function average(values: number[]) {
  if (values.length === 0) return null
  return Math.round(values.reduce((sum, v) => sum + v, 0) / values.length)
}

function averageBadge(value: number) {
  if (value >= 80) return 'bg-emerald-100 text-emerald-700'
  if (value >= 65) return 'bg-amber-100 text-amber-700'
  return 'bg-rose-100 text-rose-700'
}

/** Capacity bar color based on fill percentage */
function capacityColor(filled: number, limit: number) {
  const pct = limit > 0 ? (filled / limit) * 100 : 100
  if (pct >= 100) return { bar: 'bg-rose-500', badge: 'bg-rose-100 text-rose-700', label: 'Full' }
  if (pct >= 80) return { bar: 'bg-amber-400', badge: 'bg-amber-100 text-amber-700', label: 'Almost Full' }
  return { bar: 'bg-emerald-500', badge: 'bg-emerald-100 text-emerald-700', label: 'Available' }
}

export function ClassDetailPage() {
  const { classId: classIdParam } = useParams<{ classId: string }>()
  const [searchParams] = useSearchParams()
  const navigate = useNavigate()
  const { classes, users, scores, progress, timetable, deleteClass, updateUser } = useData()
  const { push } = useToast()
  const [editing, setEditing] = useState(false)
  const [provisionOpen, setProvisionOpen] = useState(false)
  const [provisionSearch, setProvisionSearch] = useState('')
  const [provisioning, setProvisioning] = useState<string | null>(null) // studentId being processed

  const classId = classIdParam ? decodeURIComponent(classIdParam) : ''
  const schoolClass = classes.find((c) => c.id === classId)
  const subject = searchParams.get('subject') ?? ''

  const students = useMemo(
    () => users.filter((u) => u.role === 'student' && u.classId === classId),
    [users, classId],
  )

  const limit = schoolClass?.studentLimit ?? 40
  const enrolled = students.length
  const cap = capacityColor(enrolled, limit)
  const fillPct = Math.min(100, limit > 0 ? (enrolled / limit) * 100 : 100)

  // Students that can be added: same grade/year, not in any class (unassigned) OR in a different class
  const candidatesToAdd = useMemo(() => {
    if (!schoolClass) return []
    return users.filter(
      (u) =>
        u.role === 'student' &&
        u.status !== 'GRADUATED' &&
        u.classId !== classId &&
        (u.grade === schoolClass.grade || !u.grade),
    )
  }, [users, classId, schoolClass])

  const filteredCandidates = useMemo(() => {
    const q = provisionSearch.toLowerCase()
    return candidatesToAdd.filter(
      (u) =>
        !q ||
        u.fullName.toLowerCase().includes(q) ||
        u.email.toLowerCase().includes(q),
    )
  }, [candidatesToAdd, provisionSearch])

  const classSubjects = useMemo(() => {
    const slots = timetable.filter((s) => s.classId === classId)
    const map = new Map<string, Set<string>>()
    for (const slot of slots) {
      if (!map.has(slot.subject)) map.set(slot.subject, new Set())
      if (slot.teacher) map.get(slot.subject)!.add(slot.teacher)
    }
    return Array.from(map.entries())
      .map(([name, teacherSet]) => ({ subject: name, teachers: Array.from(teacherSet) }))
      .sort((a, b) => a.subject.localeCompare(b.subject))
  }, [timetable, classId])

  const teachers = useMemo(() => users.filter((u) => u.role === 'teacher'), [users])
  const homeroom = users.find((u) => u.email === schoolClass?.homeroomTeacher)

  if (!schoolClass) {
    return (
      <div className="space-y-4">
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="text-sm font-semibold text-indigo-600 hover:text-indigo-800"
        >
          ← Back
        </button>
        <Card title="Class not found" description="No class is registered with that id.">
          <Link to="/dashboard" className="text-sm font-semibold text-indigo-600 hover:text-indigo-800">
            Return to dashboard
          </Link>
        </Card>
      </div>
    )
  }

  const handleDelete = () => {
    if (students.length > 0) {
      push('error', `${schoolClass.name} has ${students.length} enrolled student(s). Reassign them first.`)
      return
    }
    if (!window.confirm(`Delete ${schoolClass.name}? This cannot be undone.`)) return
    deleteClass(schoolClass.id)
    push('info', `${schoolClass.name} was removed.`)
    navigate('/dashboard')
  }

  const handleEnroll = async (student: User) => {
    if (!student.userId) {
      push('error', 'Student has no server ID.')
      return
    }
    setProvisioning(student.userId)
    try {
      await enrollStudentInClass(classId, student.userId)
      updateUser(student.email, { classId, grade: schoolClass.grade, status: 'ACTIVE' })
      push('success', `${student.fullName} added to ${schoolClass.name}.`)
    } catch (err: any) {
      push('error', err?.message || 'Failed to enroll student.')
    } finally {
      setProvisioning(null)
    }
  }

  const handleRemove = async (student: User) => {
    if (!student.userId) {
      push('error', 'Student has no server ID.')
      return
    }
    if (!window.confirm(`Remove ${student.fullName} from ${schoolClass.name}?`)) return
    setProvisioning(student.userId)
    try {
      await removeStudentFromClass(classId, student.userId)
      updateUser(student.email, { classId: undefined, grade: undefined })
      push('info', `${student.fullName} removed from ${schoolClass.name}.`)
    } catch (err: any) {
      push('error', err?.message || 'Failed to remove student.')
    } finally {
      setProvisioning(null)
    }
  }

  return (
    <div className="space-y-5">
      <button
        type="button"
        onClick={() => navigate(-1)}
        className="text-sm font-semibold text-indigo-600 hover:text-indigo-800"
      >
        ← Back
      </button>

      {/* ── Hero header card ── */}
      <div className="bg-white border border-slate-200 rounded-xl shadow-sm p-5">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex flex-wrap items-center gap-2 mb-1">
              <h1 className="text-2xl font-bold text-slate-900">{schoolClass.name}</h1>
              <span className="inline-flex items-center rounded-full bg-indigo-100 text-indigo-700 px-2.5 py-0.5 text-sm font-semibold">
                Grade {schoolClass.grade}
              </span>
              <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ${cap.badge}`}>
                {cap.label}
              </span>
            </div>
            <p className="text-sm text-slate-500 mb-3">
              {schoolClass.year} · Room {schoolClass.room ?? '—'} · Homeroom:{' '}
              <span className="font-medium text-slate-700">
                {homeroom ? homeroom.fullName : 'Unassigned'}
              </span>
            </p>

            {/* Capacity bar */}
            <div className="max-w-xs">
              <div className="flex items-center justify-between mb-1">
                <span className="text-xs font-semibold text-slate-600">Student Capacity</span>
                <span className={`text-xs font-bold ${enrolled >= limit ? 'text-rose-600' : 'text-slate-700'}`}>
                  {enrolled} / {limit}
                </span>
              </div>
              <div className="h-2.5 bg-slate-100 rounded-full overflow-hidden">
                <div
                  className={`h-full rounded-full transition-all duration-500 ${cap.bar}`}
                  style={{ width: `${fillPct}%` }}
                />
              </div>
              <p className="text-xs text-slate-400 mt-1">{limit - enrolled} seat(s) remaining</p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={() => setEditing((v) => !v)}
              className="border border-slate-300 text-slate-700 hover:bg-slate-100 text-sm font-semibold rounded-md px-3 py-1.5 transition-colors"
            >
              {editing ? 'Close Edit' : '✏️ Edit Class'}
            </button>
            <button
              type="button"
              onClick={handleDelete}
              className="bg-rose-600 hover:bg-rose-700 text-white text-sm font-semibold rounded-md px-3 py-1.5 transition-colors"
            >
              Delete
            </button>
          </div>
        </div>
      </div>

      {editing && (
        <ClassEditForm
          schoolClass={schoolClass}
          teachers={teachers}
          onDone={() => setEditing(false)}
        />
      )}

      {/* ── Student Roster + Provisioning ── */}
      <div className="bg-white border border-slate-200 rounded-xl shadow-sm overflow-hidden">
        {/* Roster header */}
        <div className="flex flex-wrap items-center justify-between gap-3 px-5 py-4 border-b border-slate-100">
          <div>
            <h2 className="text-base font-bold text-slate-900">
              Students{' '}
              <span className="ml-1 inline-flex items-center rounded-full bg-slate-100 text-slate-600 px-2 py-0.5 text-xs font-semibold">
                {enrolled}/{limit}
              </span>
            </h2>
            <p className="text-xs text-slate-400 mt-0.5">
              {subject ? `Showing marks for ${subject}.` : 'All enrolled students.'}
            </p>
          </div>
          <button
            type="button"
            onClick={() => { setProvisionOpen((v) => !v); setProvisionSearch('') }}
            disabled={enrolled >= limit && !provisionOpen}
            className={`inline-flex items-center gap-1.5 text-sm font-semibold rounded-md px-3 py-1.5 transition-colors ${enrolled >= limit && !provisionOpen
                ? 'bg-slate-100 text-slate-400 cursor-not-allowed'
                : 'bg-indigo-600 hover:bg-indigo-700 text-white'
              }`}
          >
            {provisionOpen ? '✕ Close' : '+ Add Student'}
          </button>
        </div>

        {/* Provision panel */}
        {provisionOpen && (
          <div className="border-b border-indigo-100 bg-indigo-50 px-5 py-4">
            <div className="flex items-center gap-2 mb-3">
              <h3 className="text-sm font-bold text-indigo-800">Assign Students to {schoolClass.name}</h3>
              {enrolled >= limit && (
                <span className="text-xs font-semibold bg-rose-100 text-rose-700 px-2 py-0.5 rounded-full">
                  Class is full — increase limit in Edit Class first
                </span>
              )}
            </div>
            <input
              type="search"
              value={provisionSearch}
              onChange={(e) => setProvisionSearch(e.target.value)}
              placeholder="Search by name or email…"
              className="w-full max-w-sm border border-indigo-200 bg-white rounded-md px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 mb-3"
            />
            {filteredCandidates.length === 0 ? (
              <p className="text-sm text-slate-500">
                {candidatesToAdd.length === 0
                  ? 'No eligible students found (all students of this grade are already in classes).'
                  : 'No students match your search.'}
              </p>
            ) : (
              <div className="overflow-x-auto rounded-lg border border-indigo-100 bg-white max-h-56 overflow-y-auto">
                <table className="min-w-full text-sm">
                  <thead className="bg-indigo-50 sticky top-0">
                    <tr>
                      <th className="px-4 py-2 text-left font-semibold text-indigo-700">Name</th>
                      <th className="px-4 py-2 text-left font-semibold text-indigo-700">Email</th>
                      <th className="px-4 py-2 text-left font-semibold text-indigo-700">Current Class</th>
                      <th className="px-4 py-2 text-left font-semibold text-indigo-700">Status</th>
                      <th className="px-4 py-2" />
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredCandidates.map((u) => (
                      <tr key={u.email} className="hover:bg-indigo-50/50 transition-colors">
                        <td className="px-4 py-2 font-medium text-slate-800">{u.fullName}</td>
                        <td className="px-4 py-2 text-slate-500">{u.email}</td>
                        <td className="px-4 py-2">
                          {u.classId ? (
                            <span className="inline-flex items-center rounded-full bg-amber-100 text-amber-700 px-2 py-0.5 text-xs font-semibold">
                              {u.classId}
                            </span>
                          ) : (
                            <span className="text-slate-400 text-xs">Unassigned</span>
                          )}
                        </td>
                        <td className="px-4 py-2">
                          <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold ${u.status === 'ACTIVE' ? 'bg-emerald-100 text-emerald-700'
                              : u.status === 'PENDING_GRADE_ASSIGNMENT' ? 'bg-sky-100 text-sky-700'
                                : 'bg-slate-100 text-slate-500'
                            }`}>
                            {u.status ?? 'Unknown'}
                          </span>
                        </td>
                        <td className="px-4 py-2 text-right">
                          <button
                            type="button"
                            disabled={!!provisioning || enrolled >= limit}
                            onClick={() => handleEnroll(u)}
                            className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 disabled:opacity-40 disabled:cursor-not-allowed"
                          >
                            {provisioning === u.userId ? 'Adding…' : 'Add →'}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* Enrolled students table */}
        {students.length === 0 ? (
          <div className="px-5 py-8 text-center">
            <p className="text-sm text-slate-400">No students enrolled in this class yet.</p>
            <button
              type="button"
              onClick={() => setProvisionOpen(true)}
              className="mt-3 text-sm font-semibold text-indigo-600 hover:text-indigo-800"
            >
              + Add the first student
            </button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide w-10">#</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Student</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">Email</th>
                  {subject && (
                    <>
                      <th className="px-4 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wide">{subject} Marks</th>
                      <th className="px-4 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wide">Avg</th>
                    </>
                  )}
                  <th className="px-4 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wide">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {students.map((student, idx) => (
                  <StudentRow
                    key={student.email}
                    idx={idx + 1}
                    student={student}
                    classId={classId}
                    subject={subject}
                    scores={scores}
                    provisioning={provisioning}
                    onRemove={handleRemove}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {classSubjects.length > 0 && (
        <Card title="Subjects & Teachers" description="Select a subject to review marks for this class.">
          <div className="flex flex-wrap gap-2 mb-3">
            <Link
              to={classDetailPath(classId)}
              className={`rounded-full px-3 py-1 text-sm font-semibold ${subject === '' ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                }`}
            >
              All
            </Link>
            {classSubjects.map((s) => (
              <Link
                key={s.subject}
                to={classDetailPath(classId, s.subject)}
                className={`rounded-full px-3 py-1 text-sm font-semibold ${subject === s.subject ? 'bg-indigo-600 text-white' : 'bg-slate-100 text-slate-700 hover:bg-slate-200'
                  }`}
              >
                {s.subject}
              </Link>
            ))}
          </div>
          <ul className="divide-y divide-slate-100">
            {classSubjects.map((s) => (
              <li key={s.subject} className="flex flex-wrap items-center justify-between gap-2 py-2 text-sm">
                <span className="font-semibold text-slate-900">{s.subject}</span>
                <span className="text-slate-600">
                  {s.teachers.length === 0 ? (
                    <span className="text-slate-400">Unassigned</span>
                  ) : (
                    s.teachers.map((name, i) => {
                      const teacher = users.find((u) => u.fullName === name)
                      return (
                        <span key={name}>
                          {i > 0 ? ', ' : ''}
                          {teacher ? (
                            <Link to={userDetailPath(teacher.email)} className="text-indigo-600 hover:text-indigo-800 hover:underline">
                              {name}
                            </Link>
                          ) : (
                            name
                          )}
                        </span>
                      )
                    })
                  )}
                </span>
              </li>
            ))}
          </ul>
        </Card>
      )}

      <SemesterProgress
        subjects={classSubjects.map((s) => s.subject)}
        schoolClass={schoolClass}
      />

      <Card
        title={`Students (${students.length})`}
        description={subject ? `Showing marks for ${subject}.` : undefined}
      >
        {students.length === 0 ? (
          <p className="text-sm text-slate-500">No students enrolled in this class.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="border-b border-slate-200 text-left text-slate-500">
                  <th className="py-2 pr-4">Name</th>
                  <th className="py-2 pr-4">Email</th>
                  {subject ? (
                    <>
                      <th className="py-2 pr-4">{subject} Marks</th>
                      <th className="py-2 pr-2 text-right">Average</th>
                    </>
                  ) : null}
                </tr>
              </thead>
              <tbody>
                {students.map((student) => (
                  <StudentRow
                    key={student.email}
                    student={student}
                    classId={classId}
                    subject={subject}
                    scores={scores}
                  />
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {subject ? <SubjectProgress students={students} subject={subject} progress={progress} /> : null}
    </div>
  )
}

function StudentRow({
  idx,
  student,
  classId,
  subject,
  scores,
  provisioning,
  onRemove,
}: {
  idx: number
  student: User
  classId: string
  subject: string
  scores: ScoreDetail[]
  provisioning: string | null
  onRemove: (s: User) => void
}) {
  const studentScores = subject
    ? scores.filter((s) => s.studentEmail === student.email && s.classId === classId && s.subject === subject)
    : []
  const avg = average(studentScores.map((s) => s.scoreReceived))

  return (
    <tr className="hover:bg-slate-50 transition-colors">
      <td className="px-4 py-3 text-slate-400 text-xs">{idx}</td>
      <td className="px-4 py-3 font-semibold">
        <Link to={userDetailPath(student.email)} className="text-indigo-600 hover:text-indigo-800 hover:underline">
          {student.fullName}
        </Link>
      </td>
      <td className="px-4 py-3 text-slate-500">{student.email}</td>
      {subject && (
        <>
          <td className="px-4 py-3">
            {studentScores.length === 0 ? (
              <span className="text-slate-400 text-xs">No marks</span>
            ) : (
              <div className="flex flex-wrap gap-1">
                {studentScores.map((s) => (
                  <span
                    key={s.id}
                    title={s.description}
                    className="inline-flex items-center rounded-full bg-slate-100 px-2 py-0.5 text-xs font-semibold text-slate-700"
                  >
                    {s.scoreReceived}
                  </span>
                ))}
              </div>
            )}
          </td>
          <td className="px-4 py-3 text-right">
            {avg === null ? (
              <span className="text-slate-400">—</span>
            ) : (
              <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold ${averageBadge(avg)}`}>
                {avg}
              </span>
            )}
          </td>
        </>
      )}
      <td className="px-4 py-3 text-right">
        <button
          type="button"
          disabled={!!provisioning}
          onClick={() => onRemove(student)}
          className="text-xs font-semibold text-rose-500 hover:text-rose-700 disabled:opacity-40 disabled:cursor-not-allowed transition-colors"
        >
          {provisioning === student.userId ? 'Removing…' : 'Remove'}
        </button>
      </td>
    </tr>
  )
}

function SubjectProgress({
  students,
  subject,
  progress,
}: {
  students: User[]
  subject: string
  progress: ReturnType<typeof useData>['progress']
}) {
  const emails = new Set(students.map((s) => s.email))
  const entries = progress.filter((p) => p.subject === subject && emails.has(p.studentEmail))

  if (entries.length === 0) return null

  const byEmail = new Map(students.map((s) => [s.email, s.fullName]))

  return (
    <Card title={`${subject} Progress`} description="Term-by-term progress notes for this class.">
      <ul className="space-y-2">
        {entries.map((p) => (
          <li key={p.id} className="rounded-lg border border-slate-200 px-3 py-2 text-sm">
            <p className="font-semibold text-slate-900">
              {byEmail.get(p.studentEmail) ?? p.studentEmail} · {p.testName}{' '}
              <span className="ml-1 text-indigo-600">{p.score}</span>
            </p>
            <p className="text-xs text-slate-500">
              {p.term} · {p.remark}
            </p>
          </li>
        ))}
      </ul>
    </Card>
  )
}

interface ClassEditFormState {
  name: string
  grade: string
  year: string
  homeroomTeacher: string
  room: string
  studentLimit: string
}

function ClassEditForm({
  schoolClass,
  teachers,
  onDone,
}: {
  schoolClass: SchoolClass
  teachers: User[]
  onDone: () => void
}) {
  const { updateClass } = useData()
  const { push } = useToast()
  const [form, setForm] = useState<ClassEditFormState>({
    name: schoolClass.name,
    grade: String(schoolClass.grade),
    year: schoolClass.year,
    homeroomTeacher: schoolClass.homeroomTeacher ?? '',
    room: schoolClass.room ?? '',
    studentLimit: String(schoolClass.studentLimit ?? 40),
  })
  const [errors, setErrors] = useState<Partial<Record<keyof ClassEditFormState, string>>>({})

  const update = <K extends keyof ClassEditFormState>(key: K, value: ClassEditFormState[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }))

  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const next: Partial<Record<keyof ClassEditFormState, string>> = {}
    if (!form.name.trim()) next.name = 'Class name is required.'
    if (!form.year.trim()) next.year = 'Academic year is required.'
    if (!form.studentLimit.trim() || isNaN(Number(form.studentLimit)) || Number(form.studentLimit) <= 0) {
      next.studentLimit = 'Student limit must be a positive number.'
    }
    setErrors(next)
    if (Object.keys(next).length > 0) return

    updateClass(schoolClass.id, {
      name: form.name.trim(),
      grade: Number(form.grade) as Grade,
      year: form.year.trim(),
      room: form.room.trim() || undefined,
      homeroomTeacher: form.homeroomTeacher || undefined,
      studentLimit: Number(form.studentLimit),
    })
    push('success', 'Class updated.')
    onDone()
  }

  return (
    <Card title="Edit Class" description={`${schoolClass.id} · the class ID cannot be changed.`}>
      <form onSubmit={submit} noValidate className="grid gap-3 sm:grid-cols-2">
        <FormField
          label="Class Name"
          name="editClassName"
          value={form.name}
          onChange={(e) => update('name', e.target.value)}
          error={errors.name}
        />
        <FormField
          as="select"
          label="Grade"
          name="editClassGrade"
          value={form.grade}
          onChange={(e) => update('grade', e.target.value)}
        >
          <option value="10">Grade 10</option>
          <option value="11">Grade 11</option>
          <option value="12">Grade 12</option>
        </FormField>
        <FormField
          label="Academic Year"
          name="editClassYear"
          value={form.year}
          onChange={(e) => update('year', e.target.value)}
          error={errors.year}
        />
        <FormField
          label="Room"
          name="editClassRoom"
          value={form.room}
          onChange={(e) => update('room', e.target.value)}
        />
        <FormField
          type="number"
          label="Student Limit"
          name="editClassStudentLimit"
          value={form.studentLimit}
          onChange={(e) => update('studentLimit', e.target.value)}
          error={errors.studentLimit}
        />
        <FormField
          as="select"
          label="Homeroom Teacher (optional)"
          name="editClassHomeroom"
          value={form.homeroomTeacher}
          onChange={(e) => update('homeroomTeacher', e.target.value)}
        >
          <option value="">Unassigned</option>
          {teachers.map((t) => (
            <option key={t.email} value={t.email}>
              {t.fullName} ({t.subject})
            </option>
          ))}
        </FormField>
        <div className="sm:col-span-2 flex items-center gap-2">
          <button
            type="submit"
            className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2 transition-colors"
          >
            Save Changes
          </button>
          <button
            type="button"
            onClick={onDone}
            className="border border-slate-300 text-slate-700 hover:bg-slate-100 font-semibold rounded-md px-4 py-2 transition-colors"
          >
            Cancel
          </button>
        </div>
      </form>
    </Card>
  )
}

function progressBadge(pct: number) {
  if (pct >= 80) return 'bg-emerald-100 text-emerald-700'
  if (pct >= 40) return 'bg-amber-100 text-amber-700'
  return 'bg-rose-100 text-rose-700'
}

function progressBar(pct: number) {
  if (pct >= 80) return 'bg-emerald-500'
  if (pct >= 40) return 'bg-amber-500'
  return 'bg-rose-500'
}

interface SemesterFormState {
  id: string
  name: string
  year: string
  startDate: string
  endDate: string
}

const SEMESTER_INITIAL: SemesterFormState = {
  id: '',
  name: '',
  year: '',
  startDate: '',
  endDate: '',
}

function SemesterProgress({
  subjects,
  schoolClass,
}: {
  subjects: string[]
  schoolClass: SchoolClass
}) {
  const {
    semesters,
    exams,
    timetable,
    addSemester,
    updateSemester,
    deleteSemester,
    addExam,
    updateExam,
    deleteExam,
  } = useData()
  const { push } = useToast()

  const [selectedId, setSelectedId] = useState('')
  const [mode, setMode] = useState<'create' | 'edit' | null>(null)
  const [form, setForm] = useState<SemesterFormState>(SEMESTER_INITIAL)
  const [errors, setErrors] = useState<Partial<Record<keyof SemesterFormState, string>>>({})
  const [expanded, setExpanded] = useState<string | null>(null)

  const activeId = selectedId || semesters[0]?.id || ''
  const semester = semesters.find((s) => s.id === activeId)

  const update = <K extends keyof SemesterFormState>(key: K, value: SemesterFormState[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }))

  const openCreate = () => {
    setForm(SEMESTER_INITIAL)
    setErrors({})
    setMode('create')
  }

  const openEdit = () => {
    if (!semester) return
    setForm({
      id: semester.id,
      name: semester.name,
      year: semester.year,
      startDate: semester.startDate,
      endDate: semester.endDate,
    })
    setErrors({})
    setMode('edit')
  }

  const submitSemester = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const next: Partial<Record<keyof SemesterFormState, string>> = {}
    const id = form.id.trim()
    if (mode === 'create') {
      if (!id) next.id = 'Semester ID is required.'
      else if (semesters.some((s) => s.id.toLowerCase() === id.toLowerCase()))
        next.id = 'This ID already exists.'
    }
    if (!form.name.trim()) next.name = 'Name is required.'
    if (!form.year.trim()) next.year = 'Academic year is required.'
    setErrors(next)
    if (Object.keys(next).length > 0) return

    if (mode === 'create') {
      addSemester({
        id,
        name: form.name.trim(),
        year: form.year.trim(),
        startDate: form.startDate,
        endDate: form.endDate,
      })
      setSelectedId(id)
      push('success', `Semester ${form.name.trim()} created.`)
    } else if (mode === 'edit' && semester) {
      updateSemester(semester.id, {
        name: form.name.trim(),
        year: form.year.trim(),
        startDate: form.startDate,
        endDate: form.endDate,
      })
      push('success', 'Semester updated.')
    }
    setMode(null)
  }

  const removeSemester = () => {
    if (!semester) return
    const count = exams.filter((e) => e.semesterId === semester.id).length
    if (!window.confirm(`Delete ${semester.name}? This also removes its ${count} exam(s). This cannot be undone.`))
      return
    deleteSemester(semester.id)
    setSelectedId('')
    setExpanded(null)
    push('info', `${semester.name} was removed.`)
  }

  return (
    <Card
      title="Semester Progress"
      description="Completion is the share of planned exams marked done for each subject."
    >
      <div className="flex flex-wrap items-end gap-2 mb-4">
        <label className="text-sm">
          <span className="block text-slate-600 font-medium mb-1">Semester</span>
          <select
            value={activeId}
            onChange={(e) => {
              setSelectedId(e.target.value)
              setExpanded(null)
              setMode(null)
            }}
            className="rounded-md border border-slate-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          >
            {semesters.length === 0 ? <option value="">No semesters yet</option> : null}
            {semesters.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name} · {s.year}
              </option>
            ))}
          </select>
        </label>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={openCreate}
            className="bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-md px-3 py-2"
          >
            New
          </button>
          {semester && (
            <>
              <button
                type="button"
                onClick={openEdit}
                className="border border-slate-300 text-slate-700 hover:bg-slate-100 text-sm font-semibold rounded-md px-3 py-2"
              >
                Edit
              </button>
              <button
                type="button"
                onClick={removeSemester}
                className="text-rose-600 hover:text-rose-800 text-sm font-semibold rounded-md px-3 py-2"
              >
                Delete
              </button>
            </>
          )}
        </div>
      </div>

      {semester && (
        <p className="text-xs text-slate-500 mb-3">
          {semester.startDate || '—'} → {semester.endDate || '—'}
        </p>
      )}

      {mode && (
        <form
          onSubmit={submitSemester}
          noValidate
          className="grid gap-3 sm:grid-cols-2 border border-slate-200 rounded-lg p-3 mb-4 bg-slate-50"
        >
          {mode === 'create' && (
            <FormField
              label="Semester ID"
              name="semId"
              value={form.id}
              onChange={(e) => update('id', e.target.value)}
              error={errors.id}
              hint="Short code, e.g. S1-2025."
            />
          )}
          <FormField
            label="Name"
            name="semName"
            value={form.name}
            onChange={(e) => update('name', e.target.value)}
            error={errors.name}
          />
          <FormField
            label="Academic Year"
            name="semYear"
            value={form.year}
            onChange={(e) => update('year', e.target.value)}
            error={errors.year}
          />
          <FormField
            type="date"
            label="Start Date"
            name="semStart"
            value={form.startDate}
            onChange={(e) => update('startDate', e.target.value)}
          />
          <FormField
            type="date"
            label="End Date"
            name="semEnd"
            value={form.endDate}
            onChange={(e) => update('endDate', e.target.value)}
          />
          <div className="sm:col-span-2 flex items-center gap-2">
            <button
              type="submit"
              className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2"
            >
              {mode === 'create' ? 'Create Semester' : 'Save Changes'}
            </button>
            <button
              type="button"
              onClick={() => setMode(null)}
              className="border border-slate-300 text-slate-700 hover:bg-slate-100 font-semibold rounded-md px-4 py-2"
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {semesters.length === 0 ? (
        <p className="text-sm text-slate-500">Create a semester to start tracking exam progress.</p>
      ) : subjects.length === 0 ? (
        <p className="text-sm text-slate-500">This class has no subjects on the timetable yet.</p>
      ) : (
        <ul className="space-y-2">
          {subjects.map((subjectName) => {
            const slot = timetable.find((s) => s.classId === schoolClass.id && s.subject === subjectName)
            const teacherEmail = slot?.teacher || schoolClass.homeroomTeacher || ''
            return (
              <SubjectExamRow
                key={subjectName}
                subject={subjectName}
                semesterId={activeId}
                classId={schoolClass.id}
                teacherEmail={teacherEmail}
                exams={exams.filter(
                  (e) => e.semesterId === activeId && e.subject === subjectName,
                )}
                expanded={expanded === subjectName}
                onToggle={() =>
                  setExpanded((prev) => (prev === subjectName ? null : subjectName))
                }
                addExam={addExam}
                updateExam={updateExam}
                deleteExam={deleteExam}
                push={push}
              />
            )
          })}
        </ul>
      )}
    </Card>
  )
}

function SubjectExamRow({
  subject,
  semesterId,
  classId,
  teacherEmail,
  exams,
  expanded,
  onToggle,
  addExam,
  updateExam,
  deleteExam,
  push,
}: {
  subject: string
  semesterId: string
  classId: string
  teacherEmail: string
  exams: Exam[]
  expanded: boolean
  onToggle: () => void
  addExam: (exam: Omit<Exam, 'id'>, teacherEmail: string) => void
  updateExam: (id: number, patch: Partial<Omit<Exam, 'id'>>) => void
  deleteExam: (id: number) => void
  push: (type: 'success' | 'error' | 'info', message: string) => void
}) {
  const [examName, setExamName] = useState('')
  const [examDate, setExamDate] = useState('')

  const total = exams.length
  const done = exams.filter((e) => e.completed).length
  const pct = total === 0 ? 0 : Math.round((done / total) * 100)

  const addExamSubmit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!examName.trim()) {
      push('error', 'Exam name is required.')
      return
    }
    addExam({
      classId,
      semesterId,
      subject,
      name: examName.trim(),
      date: examDate,
      completed: false,
    }, teacherEmail)
    setExamName('')
    setExamDate('')
    push('success', `Exam added to ${subject}.`)
  }

  return (
    <li className="border border-slate-200 rounded-lg px-3 py-2">
      <button
        type="button"
        onClick={onToggle}
        className="w-full flex items-center gap-3 text-left"
      >
        <span className="font-semibold text-slate-900 min-w-[7rem]">{subject}</span>
        <span className="flex-1 h-2 rounded-full bg-slate-100 overflow-hidden">
          <span
            className={`block h-full ${progressBar(pct)}`}
            style={{ width: `${pct}%` }}
          />
        </span>
        <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold ${progressBadge(pct)}`}>
          {pct}%
        </span>
        <span className="text-xs text-slate-500 w-16 text-right">{done}/{total} done</span>
        <span className="text-slate-400 text-xs">{expanded ? '▲' : '▼'}</span>
      </button>

      {expanded && (
        <div className="mt-3 space-y-2">
          {exams.length === 0 ? (
            <p className="text-sm text-slate-500">No exams planned yet.</p>
          ) : (
            <ul className="space-y-1">
              {exams.map((exam) => (
                <li
                  key={exam.id}
                  className="flex flex-wrap items-center gap-2 text-sm border-b border-slate-100 pb-1"
                >
                  <label className="flex items-center gap-2 flex-1">
                    <input
                      type="checkbox"
                      checked={exam.completed}
                      onChange={() => updateExam(exam.id, { completed: !exam.completed })}
                      className="h-4 w-4 rounded border-slate-300 text-indigo-600 focus:ring-indigo-500"
                    />
                    <span className={exam.completed ? 'line-through text-slate-400' : 'text-slate-800'}>
                      {exam.name}
                    </span>
                  </label>
                  <span className="text-xs text-slate-500">{exam.date || 'No date'}</span>
                  <button
                    type="button"
                    onClick={() => deleteExam(exam.id)}
                    className="text-rose-600 hover:text-rose-800 text-xs font-semibold"
                  >
                    Delete
                  </button>
                </li>
              ))}
            </ul>
          )}

          <form onSubmit={addExamSubmit} className="flex flex-wrap items-end gap-2 pt-1">
            <input
              type="text"
              value={examName}
              onChange={(e) => setExamName(e.target.value)}
              placeholder="Exam name"
              className="flex-1 min-w-[8rem] rounded-md border border-slate-300 px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
            <input
              type="date"
              value={examDate}
              onChange={(e) => setExamDate(e.target.value)}
              className="rounded-md border border-slate-300 px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
            <button
              type="submit"
              className="bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-md px-3 py-1.5"
            >
              Add Exam
            </button>
          </form>
        </div>
      )}
    </li>
  )
}
