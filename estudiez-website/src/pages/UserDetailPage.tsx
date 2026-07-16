import { useEffect, useMemo, useState, Fragment } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { Card } from '../components/Card'
import { FormField } from '../components/FormField'
import { useData } from '../hooks/useData'
import { useToast } from '../hooks/useToast'
import { useAuth } from '../hooks/useAuth'
import { classDetailPath } from './classDetailPath'
import { userDetailPath } from './userDetailPath'
import type { AttendanceStatus, Grade, Role, User } from '../types'
import {
  getStudents,
  getUsers,
  updateApiUser,
  updateApiStudent,
  enrollStudentInClass,
  linkParentToStudent,
} from '../services/api'

const ROLE_BADGE: Record<Role, string> = {
  admin: 'bg-slate-200 text-slate-700',
  teacher: 'bg-indigo-100 text-indigo-700',
  student: 'bg-emerald-100 text-emerald-700',
  parent: 'bg-amber-100 text-amber-700',
}

const ATTENDANCE_BADGE: Record<AttendanceStatus, string> = {
  present: 'bg-emerald-100 text-emerald-700',
  absent: 'bg-rose-100 text-rose-700',
  late: 'bg-amber-100 text-amber-700',
  excused: 'bg-slate-200 text-slate-600',
}

const PHONE_PATTERN = /^[+\d][\d\s().-]{6,}$/
const PERIOD_TIMES: Record<number, { start: string; end: string }> = {
  1: { start: '07:30', end: '08:15' },
  2: { start: '08:25', end: '09:10' },
  3: { start: '09:20', end: '10:05' },
  4: { start: '10:15', end: '11:00' },
  5: { start: '11:10', end: '11:55' },
  6: { start: '13:00', end: '13:45' },
  7: { start: '13:50', end: '14:35' },
}
const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/

interface EditFormState {
  fullName: string
  address: string
  phone: string
  age: string
  classId: string
  parentEmail: string
  subject: string
  childEmail: string
  username: string
  studentCode: string
  dateOfBirth: string
  gender: string
  admissionDate: string
  status: string
  grade: string
  password: string
}

type EditErrors = Partial<Record<keyof EditFormState, string>>

export function UserDetailPage() {
  const { email: emailParam } = useParams<{ email: string }>()
  const navigate = useNavigate()
  const { users, classes, scores, attendance, progress, evaluations, updateUser, deleteUser } =
    useData()
  const { push } = useToast()
  const { currentUser } = useAuth()

  const [editing, setEditing] = useState(false)

  const email = (emailParam ? decodeURIComponent(emailParam) : '').toLowerCase()
  const user = users.find((u) => u.email.toLowerCase() === email)

  const [studentProfile, setStudentProfile] = useState<any>(null)
  const [userProfile, setUserProfile] = useState<any>(null)

  useEffect(() => {
    if (user) {
      getUsers()
        .then((list) => {
          const profile = list.find((u) => u.email?.toLowerCase() === user.email.toLowerCase())
          setUserProfile(profile || null)
        })
        .catch(console.error)
    }
  }, [user])

  useEffect(() => {
    if (user?.role === 'student' && user.studentId) {
      getStudents()
        .then((list) => {
          const profile = list.find((s) => String(s.studentId).toLowerCase() === user.studentId?.toLowerCase())
          setStudentProfile(profile || null)
        })
        .catch(console.error)
    }
  }, [user])

  if (!user) {
    return (
      <div className="space-y-4">
        <button
          type="button"
          onClick={() => navigate(-1)}
          className="text-sm font-semibold text-indigo-600 hover:text-indigo-800"
        >
          ← Back
        </button>
        <Card title="User not found" description="No account is registered with that email.">
          <Link to="/dashboard" className="text-sm font-semibold text-indigo-600 hover:text-indigo-800">
            Return to dashboard
          </Link>
        </Card>
      </div>
    )
  }

  const linkedParent = users.find((u) => u.role === 'parent' && u.childEmail === user.email)

  const handleDelete = () => {
    if (user.role === 'teacher') {
      const homeroomOf = classes.find((c) => c.homeroomTeacher === user.email)
      if (homeroomOf) {
        push(
          'error',
          `${user.fullName} is homeroom teacher of ${homeroomOf.name}. Reassign the class first.`,
        )
        return
      }
    }
    if (!window.confirm(`Delete ${user.fullName}? This cannot be undone.`)) return
    if (user.role === 'student' && linkedParent) {
      updateUser(linkedParent.email, { childEmail: undefined })
    }
    deleteUser(user.email)
    push('info', `${user.fullName} was removed.`)
    navigate('/dashboard')
  }

  return (
    <div className="space-y-4">
      <button
        type="button"
        onClick={() => navigate(-1)}
        className="text-sm font-semibold text-indigo-600 hover:text-indigo-800"
      >
        ← Back
      </button>

      <header className="flex flex-wrap items-center gap-3">
        <div className="flex h-14 w-14 items-center justify-center rounded-full bg-indigo-600 text-xl font-bold text-white">
          {user.fullName.charAt(0).toUpperCase()}
        </div>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-slate-900">{user.fullName}</h1>
          <span
            className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold uppercase ${ROLE_BADGE[user.role]}`}
          >
            {user.role}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => setEditing((prev) => !prev)}
            className="rounded-md border border-slate-300 px-3 py-1.5 text-sm font-semibold text-slate-700 hover:bg-slate-100"
          >
            {editing ? 'Close Editor' : 'Edit'}
          </button>
          <button
            type="button"
            onClick={handleDelete}
            className="rounded-md bg-rose-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-rose-700"
          >
            Delete
          </button>
        </div>
      </header>

      {editing ? (
        <EditUserForm
          user={user}
          userProfile={userProfile}
          studentProfile={studentProfile}
          linkedParent={linkedParent}
          onDone={() => setEditing(false)}
        />
      ) : null}

      <Card title="Account Details">
        <dl className="grid gap-4 sm:grid-cols-2 text-sm">
          <Detail label="Email" value={user.email} />
          <Detail label="Phone" value={user.phone ?? '—'} />
          <Detail label="Address" value={user.address || '—'} />
          {user.age ? <Detail label="Age" value={String(user.age)} /> : null}
          {currentUser?.role === 'admin' ? (
            <div>
              <dt className="text-xs font-semibold uppercase text-slate-500">Password</dt>
              {user.password ? (
                <dd className="mt-1 flex items-center gap-2">
                  <span className="font-mono text-sm text-indigo-700 bg-indigo-50 border border-indigo-100 px-2 py-0.5 rounded select-all">
                    {user.password}
                  </span>
                  <button
                    type="button"
                    onClick={() => {
                      navigator.clipboard.writeText(user.password)
                    }}
                    className="text-xs text-slate-500 hover:text-slate-700 border border-slate-300 rounded px-2 py-0.5 hover:bg-slate-50 transition-colors"
                    title="Copy password"
                  >
                    Copy
                  </button>
                </dd>
              ) : (
                <dd className="mt-1 text-sm text-slate-400 italic">
                  Not available — set via Edit to update
                </dd>
              )}
            </div>
          ) : null}
        </dl>
      </Card>

      {user.role === 'student' ? (
        <StudentDetail
          user={user}
          classes={classes}
          scores={scores}
          attendance={attendance}
          progress={progress}
          evaluations={evaluations}
          parent={linkedParent}
        />
      ) : null}

      {user.role === 'teacher' ? <TeacherDetail user={user} /> : null}

      {user.role === 'parent' ? (
        <ParentDetail
          user={user}
          child={users.find((u) => u.role === 'student' && u.email === user.childEmail)}
        />
      ) : null}
    </div>
  )
}

function EditUserForm({
  user,
  userProfile,
  studentProfile,
  linkedParent,
  onDone,
}: {
  user: User
  userProfile?: any
  studentProfile?: any
  linkedParent?: User
  onDone: () => void
}) {
  const { users, classes, subjects, refreshData } = useData()
  const { push } = useToast()
  const { currentUser } = useAuth()
  const [submitting, setSubmitting] = useState(false)

  const [form, setForm] = useState<EditFormState>({
    fullName: user.fullName,
    address: user.address,
    phone: user.phone ?? '',
    age: user.age ? String(user.age) : '',
    classId: user.classId ?? '',
    parentEmail: linkedParent?.email ?? '',
    subject: user.subject ?? '',
    childEmail: user.childEmail ?? '',
    username: userProfile?.username ?? user.email.split('@')[0],
    studentCode: studentProfile?.studentCode ?? '',
    dateOfBirth: studentProfile?.dateOfBirth ?? '',
    gender: studentProfile?.gender ?? 'Male',
    admissionDate: studentProfile?.admissionDate ?? '',
    status: studentProfile?.status ?? 'ACTIVE',
    grade: user.grade ? String(user.grade) : '10',
    password: user.password ?? '',
  })
  const [errors, setErrors] = useState<EditErrors>({})

  useEffect(() => {
    if (studentProfile) {
      setForm((prev) => ({
        ...prev,
        studentCode: studentProfile.studentCode ?? '',
        dateOfBirth: studentProfile.dateOfBirth ?? '',
        gender: studentProfile.gender ?? 'Male',
        admissionDate: studentProfile.admissionDate ?? '',
        status: studentProfile.status ?? 'ACTIVE',
      }))
    }
  }, [studentProfile])

  useEffect(() => {
    if (userProfile) {
      setForm((prev) => ({
        ...prev,
        username: userProfile.username ?? '',
      }))
    }
  }, [userProfile])

  const update = <K extends keyof EditFormState>(key: K, value: EditFormState[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }))

  const submit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const next: EditErrors = {}
    if (!form.fullName.trim()) next.fullName = 'Full name is required.'
    if (!form.address.trim()) next.address = 'Address is required.'
    if (!form.phone.trim()) next.phone = 'Phone number is required.'
    else if (!PHONE_PATTERN.test(form.phone.trim())) next.phone = 'Enter a valid phone number.'

    if (user.role === 'student') {
      if (!form.username.trim()) next.username = 'Username is required.'
      if (!form.studentCode.trim()) next.studentCode = 'Student code is required.'
      if (!form.dateOfBirth) next.dateOfBirth = 'Date of birth is required.'
      if (!form.admissionDate) next.admissionDate = 'Admission date is required.'

      const isGrade9OrPending = form.grade === '9' || form.status === 'PENDING_GRADE_ASSIGNMENT'
      if (!isGrade9OrPending && !form.classId) next.classId = 'Assign a class.'

      if (form.parentEmail && !EMAIL_PATTERN.test(form.parentEmail))
        next.parentEmail = 'Enter a valid parent email or leave blank.'
    }
    if (user.role === 'teacher' && !form.subject) next.subject = 'Assign a subject.'
    if (user.role === 'parent' && form.childEmail) {
      if (!EMAIL_PATTERN.test(form.childEmail))
        next.childEmail = 'Enter a valid student email or leave blank.'
      else if (
        !users.some(
          (u) => u.email === form.childEmail.trim().toLowerCase() && u.role === 'student',
        )
      )
        next.childEmail = 'No student account is registered with that email.'
    }

    setErrors(next)
    if (Object.keys(next).length > 0) return

    setSubmitting(true)
    try {
      // 1. Update User account
      let roleId = 1
      if (user.role === 'teacher') roleId = 2
      else if (user.role === 'student') roleId = 3
      else if (user.role === 'parent') roleId = 4

      await updateApiUser(user.userId!, {
        roleId,
        username: form.username.trim(),
        passwordHash: '',
        fullName: form.fullName.trim(),
        email: user.email,
        phone: form.phone.trim(),
        isActive: true,
        ...({ plainPassword: form.password.trim() } as any),
      })

      // 2. Update Student profile
      if (user.role === 'student' && user.studentId) {
        const selectedGrade = form.grade ? (parseInt(form.grade, 10) as Grade) : null
        await updateApiStudent(user.studentId, {
          studentId: user.studentId,
          userId: user.userId,
          studentCode: form.studentCode.trim(),
          dateOfBirth: form.dateOfBirth,
          gender: form.gender,
          address: form.address.trim(),
          admissionDate: form.admissionDate,
          status: form.status,
          currentGrade: selectedGrade,
        })

        // Enroll in class if changed
        if (form.classId && form.classId !== user.classId) {
          await enrollStudentInClass(form.classId, user.studentId)
        }
      }

      // 3. Link parent if parentEmail is provided
      if (user.role === 'student') {
        const nextParentEmail = form.parentEmail.trim().toLowerCase()
        const parentUser = users.find(
          (u) => u.email.toLowerCase() === nextParentEmail && u.role === 'parent'
        )
        if (parentUser && parentUser.parentId) {
          await linkParentToStudent(parentUser.parentId, user.email)
        }
      }

      // 4. Refresh global state
      await refreshData()

      push('success', 'Profile updated successfully.')
      onDone()
    } catch (err: any) {
      console.error(err)
      push('error', err?.message || 'Failed to update profile details.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Card
      title={`Edit ${user.fullName}`}
      description="Email and role are fixed and cannot be changed."
    >
      <form onSubmit={submit} noValidate className="grid gap-4 sm:grid-cols-2">
        <FormField
          label="Full Name"
          name="editFullName"
          value={form.fullName}
          onChange={(e) => update('fullName', e.target.value)}
          error={errors.fullName}
        />
        <FormField
          label="Phone Number"
          name="editPhone"
          type="tel"
          value={form.phone}
          onChange={(e) => update('phone', e.target.value)}
          error={errors.phone}
        />
        <FormField
          label="Address"
          name="editAddress"
          value={form.address}
          onChange={(e) => update('address', e.target.value)}
          error={errors.address}
        />

        {currentUser?.role === 'admin' && (
          <FormField
            label="Password"
            name="editPassword"
            type="text"
            value={form.password}
            onChange={(e) => update('password', e.target.value)}
            error={errors.password}
          />
        )}

        {user.role === 'student' ? (
          <>
            <FormField
              label="Username"
              name="editUsername"
              value={form.username}
              onChange={(e) => update('username', e.target.value)}
              error={errors.username}
            />
            <FormField
              label="Student Code"
              name="editStudentCode"
              value={form.studentCode}
              onChange={(e) => update('studentCode', e.target.value)}
              error={errors.studentCode}
            />
            <FormField
              label="Date of Birth"
              name="editDob"
              type="date"
              value={form.dateOfBirth}
              onChange={(e) => update('dateOfBirth', e.target.value)}
              error={errors.dateOfBirth}
            />
            <FormField
              as="select"
              label="Gender"
              name="editGender"
              value={form.gender}
              onChange={(e) => update('gender', e.target.value)}
              error={errors.gender}
            >
              <option value="Male">Male</option>
              <option value="Female">Female</option>
              <option value="Other">Other</option>
            </FormField>
            <FormField
              label="Admission Date"
              name="editAdmissionDate"
              type="date"
              value={form.admissionDate}
              onChange={(e) => update('admissionDate', e.target.value)}
              error={errors.admissionDate}
            />
            <FormField
              as="select"
              label="Grade"
              name="editGrade"
              value={form.grade}
              onChange={(e) => {
                const selectedGrade = e.target.value
                update('grade', selectedGrade)
                const gradeVal = parseInt(selectedGrade, 10)
                const matchingClasses = classes.filter((c) => c.grade === gradeVal)
                update('classId', matchingClasses[0]?.id ?? '')
              }}
              error={errors.grade}
            >
              <option value="9">Grade 9</option>
              <option value="10">Grade 10</option>
              <option value="11">Grade 11</option>
              <option value="12">Grade 12</option>
            </FormField>
            <FormField
              as="select"
              label="Class"
              name="editClass"
              value={form.classId}
              onChange={(e) => update('classId', e.target.value)}
              error={errors.classId}
              disabled={form.grade === '9' || form.status === 'PENDING_GRADE_ASSIGNMENT'}
            >
              {form.grade === '9' || form.status === 'PENDING_GRADE_ASSIGNMENT' ? (
                <option value="">Unassigned</option>
              ) : (
                <option value="">Select a class</option>
              )}
              {form.grade !== '9' && form.status !== 'PENDING_GRADE_ASSIGNMENT' && classes
                .filter((c) => String(c.grade) === form.grade)
                .map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name} (Grade {c.grade})
                  </option>
                ))}
            </FormField>
            <FormField
              as="select"
              label="Status"
              name="editStatus"
              value={form.status}
              onChange={(e) => {
                const selectedStatus = e.target.value
                update('status', selectedStatus)
                if (selectedStatus === 'PENDING_GRADE_ASSIGNMENT') {
                  update('classId', '')
                }
              }}
              error={errors.status}
            >
              <option value="ACTIVE">ACTIVE</option>
              <option value="PENDING_GRADE_ASSIGNMENT">PENDING_GRADE_ASSIGNMENT</option>
              <option value="GRADUATED">GRADUATED</option>
              <option value="TRANSFERRED">TRANSFERRED</option>
              <option value="SUSPENDED">SUSPENDED</option>
            </FormField>
            <FormField
              label="Parent Email (optional)"
              name="editParentEmail"
              type="email"
              value={form.parentEmail}
              onChange={(e) => update('parentEmail', e.target.value)}
              error={errors.parentEmail}
              hint="Links an existing parent account to this student."
            />
          </>
        ) : null}

        {user.role === 'teacher' ? (
          <FormField
            as="select"
            label="Subject"
            name="editSubject"
            value={form.subject}
            onChange={(e) => update('subject', e.target.value)}
            error={errors.subject}
          >
            <option value="">Select a subject</option>
            {subjects.map((s) => (
              <option key={s.id} value={s.name}>
                {s.name}
              </option>
            ))}
          </FormField>
        ) : null}

        {user.role === 'parent' ? (
          <FormField
            label="Child's Email (optional)"
            name="editChildEmail"
            type="email"
            value={form.childEmail}
            onChange={(e) => update('childEmail', e.target.value)}
            error={errors.childEmail}
            hint="Link this parent to a student account."
          />
        ) : null}

        <div className="sm:col-span-2 flex items-center gap-2">
          <button
            type="submit"
            disabled={submitting}
            className="rounded-md bg-indigo-600 px-4 py-2 font-semibold text-white hover:bg-indigo-700 disabled:opacity-50"
          >
            {submitting ? 'Saving...' : 'Save Changes'}
          </button>
          <button
            type="button"
            disabled={submitting}
            onClick={onDone}
            className="rounded-md border border-slate-300 px-4 py-2 font-semibold text-slate-700 hover:bg-slate-100 disabled:opacity-50"
          >
            Cancel
          </button>
        </div>
      </form>
    </Card>
  )
}

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <dt className="text-xs font-semibold uppercase text-slate-500">{label}</dt>
      <dd className="mt-1 font-medium text-slate-800">{value}</dd>
    </div>
  )
}

interface StudentDetailProps {
  user: User
  classes: ReturnType<typeof useData>['classes']
  scores: ReturnType<typeof useData>['scores']
  attendance: ReturnType<typeof useData>['attendance']
  progress: ReturnType<typeof useData>['progress']
  evaluations: ReturnType<typeof useData>['evaluations']
  parent?: User
}

function StudentDetail({
  user,
  classes,
  scores,
  attendance,
  progress,
  evaluations,
  parent,
}: StudentDetailProps) {
  const { semesters } = useData()
  const studentClass = classes.find((c) => c.id === user.classId)
  const studentScores = scores.filter((s) => s.studentEmail === user.email)
  const studentAttendance = attendance.filter((a) => a.studentEmail === user.email)
  const studentProgress = progress.filter((p) => p.studentEmail === user.email)
  const studentEvaluations = evaluations.filter((e) => e.studentEmail === user.email)

  const [selectedKey, setSelectedKey] = useState<string | null>(null)

  const [selectedSemesterId, setSelectedSemesterId] = useState(() => {
    const today = new Date().toISOString().slice(0, 10)
    
    // 1. Try to find a semester in the student's class year matching current date
    if (studentClass?.year) {
      const matchingSem = semesters.find(
        (s) => s.year === studentClass.year && today >= s.startDate && today <= s.endDate
      )
      if (matchingSem) return matchingSem.id

      // 2. Fall back to the first semester of the student's class year
      const firstSemOfClassYear = semesters.find((s) => s.year === studentClass.year)
      if (firstSemOfClassYear) return firstSemOfClassYear.id
    }

    // 3. Fall back to any semester matching the current date
    const currentSem = semesters.find((s) => today >= s.startDate && today <= s.endDate)
    if (currentSem) return currentSem.id

    // 4. Default to first semester, or empty
    return semesters[0]?.id ?? ''
  })

  const filteredScores = useMemo(() => {
    if (!selectedSemesterId) return studentScores
    const sem = semesters.find((s) => s.id === selectedSemesterId)
    if (!sem) return studentScores
    return studentScores.filter((s) => s.date >= sem.startDate && s.date <= sem.endDate)
  }, [studentScores, semesters, selectedSemesterId])

  const groupedScores = useMemo(() => {
    const map = new Map<string, typeof filteredScores>()
    for (const s of filteredScores) {
      if (!map.has(s.subject)) map.set(s.subject, [])
      map.get(s.subject)!.push(s)
    }
    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b))
  }, [filteredScores])

  const attendanceSummary = useMemo(() => {
    const summary: Record<AttendanceStatus, number> = {
      present: 0,
      absent: 0,
      late: 0,
      excused: 0,
    }
    for (const record of studentAttendance) summary[record.status] += 1
    return summary
  }, [studentAttendance])

  const scoreStyle = (s: number) => {
    if (s >= 80) return 'bg-emerald-100 text-emerald-700 border-emerald-200'
    if (s >= 65) return 'bg-indigo-100 text-indigo-700 border-indigo-200'
    if (s >= 50) return 'bg-amber-100 text-amber-700 border-amber-200'
    return 'bg-rose-100 text-rose-700 border-rose-200'
  }

  return (
    <>
      <Card title="Enrollment">
        <dl className="grid gap-4 sm:grid-cols-2 text-sm">
          <Detail label="Class" value={studentClass ? studentClass.name : user.classId ?? '—'} />
          <Detail label="Grade" value={user.grade ? String(user.grade) : '—'} />
          <div>
            <dt className="text-xs font-semibold uppercase text-slate-500">Parent / Guardian</dt>
            <dd className="mt-1 font-medium text-slate-800">
              {parent ? (
                <Link
                  to={userDetailPath(parent.email)}
                  className="text-indigo-600 hover:text-indigo-800"
                >
                  {parent.fullName}
                </Link>
              ) : (
                '—'
              )}
            </dd>
          </div>
        </dl>
      </Card>

      <Card
        title="Academic Performance"
        description="Select a semester to filter subject averages and individual test marks."
      >
        <div className="flex items-center gap-3 mb-4">
          <label className="text-sm font-semibold text-slate-600 shrink-0">Semester:</label>
          <select
            value={selectedSemesterId}
            onChange={(e) => {
              setSelectedSemesterId(e.target.value)
              setSelectedKey(null)
            }}
            className="rounded-md border border-slate-300 px-3 py-1.5 text-sm text-slate-700 bg-white"
          >
            <option value="">All semesters</option>
            {semesters.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name} ({s.year})
              </option>
            ))}
          </select>
        </div>

        {filteredScores.length === 0 ? (
          <p className="text-sm text-slate-500">No marks recorded for this period.</p>
        ) : (
          <div className="overflow-x-auto rounded-lg border border-slate-200 bg-white">
            <table className="min-w-full text-sm border-collapse">
              <thead>
                <tr className="bg-slate-50 text-slate-500 border-b border-slate-200 text-left text-xs font-semibold uppercase tracking-wider">
                  <th className="py-3 px-4">Subject</th>
                  <th className="py-3 px-4">Detailed Marks</th>
                  <th className="py-3 px-4 text-center w-24">Average</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {groupedScores.map(([subject, subjectScores]) => {
                  const avg = Math.round(
                    subjectScores.reduce((sum, s) => sum + s.scoreReceived, 0) / subjectScores.length,
                  )
                  const activeKeyForSubject = selectedKey?.startsWith(subject + ':') ? selectedKey : null
                  const selectedScoreItem = activeKeyForSubject
                    ? subjectScores.find((s) => `${subject}:${s.testId}` === activeKeyForSubject)
                    : null
                  const selectedEvalItem = selectedScoreItem
                    ? evaluations.find(
                        (e) =>
                          e.studentEmail === user.email &&
                          e.subject === subject &&
                          e.testId === selectedScoreItem.testId
                      )
                    : null

                  return (
                    <Fragment key={subject}>
                      <tr className="hover:bg-slate-50">
                        <td className="py-3 px-4 font-semibold text-slate-900">{subject}</td>
                        <td className="py-3 px-4">
                          <div className="flex flex-wrap gap-2">
                            {subjectScores.map((s) => {
                              const key = `${subject}:${s.testId}`
                              const isSelected = selectedKey === key
                              return (
                                <button
                                  key={s.id}
                                  type="button"
                                  onClick={() => setSelectedKey(isSelected ? null : key)}
                                  className={`inline-flex items-center gap-1.5 rounded px-2.5 py-1 text-xs font-semibold border transition-all hover:scale-105 ${
                                    isSelected
                                      ? 'bg-indigo-600 text-white border-indigo-700 ring-2 ring-indigo-300'
                                      : scoreStyle(s.scoreReceived)
                                  }`}
                                  title={`Click to view evaluation for ${s.description}`}
                                >
                                  <span className="opacity-80">{s.description}:</span>
                                  <span>{s.scoreReceived}</span>
                                </button>
                              )
                            })}
                          </div>
                        </td>
                        <td className="py-3 px-4 text-center">
                          <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-bold ${scoreStyle(avg)}`}>
                            {avg}
                          </span>
                        </td>
                      </tr>
                      {selectedScoreItem && (
                        <tr key={`${subject}:detail`} className="bg-indigo-50/20">
                          <td colSpan={3} className="px-4 py-3">
                            <div className="rounded-lg border border-indigo-100 bg-white p-3 shadow-sm text-xs space-y-2">
                              <div className="flex items-center justify-between border-b border-slate-100 pb-1.5">
                                <div>
                                  <span className="font-semibold text-slate-800 text-sm">{selectedScoreItem.description}</span>
                                  <span className="ml-2 font-mono text-slate-500 bg-slate-100 px-1 py-0.5 rounded text-[10px]">{selectedScoreItem.testId}</span>
                                </div>
                                <div className="flex items-center gap-2">
                                  <span className="text-slate-500">{selectedScoreItem.date}</span>
                                  <span className={`inline-flex rounded-full px-2 py-0.5 font-bold ${scoreStyle(selectedScoreItem.scoreReceived)}`}>
                                    Score: {selectedScoreItem.scoreReceived}
                                  </span>
                                </div>
                              </div>
                              
                              {selectedEvalItem ? (
                                <div className="grid gap-2 sm:grid-cols-3 pt-1">
                                  <div>
                                    <span className="font-semibold text-slate-700 block">Strengths:</span>
                                    <p className="text-slate-600 mt-0.5">{selectedEvalItem.strengths || 'None specified.'}</p>
                                  </div>
                                  <div>
                                    <span className="font-semibold text-slate-700 block">Weaknesses:</span>
                                    <p className="text-slate-600 mt-0.5">{selectedEvalItem.weaknesses || 'None specified.'}</p>
                                  </div>
                                  <div>
                                    <span className="font-semibold text-indigo-700 block">Learning Path:</span>
                                    <p className="text-indigo-700 mt-0.5 font-medium">{selectedEvalItem.suggestedPath || 'Regular course.'}</p>
                                  </div>
                                </div>
                              ) : (
                                <p className="text-slate-500 italic">No teacher evaluation or learning path generated for this test.</p>
                              )}
                            </div>
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <Card title="Attendance Summary">
        <div className="flex flex-wrap gap-3">
          {(Object.keys(attendanceSummary) as AttendanceStatus[]).map((status) => (
            <span
              key={status}
              className={`inline-flex items-center gap-1 rounded-full px-3 py-1 text-sm font-semibold ${ATTENDANCE_BADGE[status]}`}
            >
              <span className="capitalize">{status}</span>
              <span>{attendanceSummary[status]}</span>
            </span>
          ))}
        </div>
      </Card>

      {studentProgress.length > 0 ? (
        <Card title={`Progress (${studentProgress.length})`}>
          <ul className="space-y-2">
            {studentProgress.map((p) => (
              <li key={p.id} className="rounded-lg border border-slate-200 px-3 py-2 text-sm">
                <p className="font-semibold text-slate-900">
                  {p.subject} · {p.testName}{' '}
                  <span className="ml-1 text-indigo-600">{p.score}</span>
                </p>
                <p className="text-xs text-slate-500">
                  {p.term} · {p.remark}
                </p>
              </li>
            ))}
          </ul>
        </Card>
      ) : null}

      {studentEvaluations.length > 0 ? (
        <Card title={`Teacher Evaluations (${studentEvaluations.length})`}>
          <ul className="space-y-2">
            {studentEvaluations.map((e) => (
              <li key={e.id} className="rounded-lg border border-slate-200 px-3 py-2 text-sm">
                <p className="font-semibold text-slate-900">{e.subject}</p>
                <p className="text-xs text-emerald-700">Strengths: {e.strengths}</p>
                <p className="text-xs text-rose-700">Weaknesses: {e.weaknesses}</p>
                <p className="mt-1 text-xs text-slate-600">Path: {e.suggestedPath}</p>
              </li>
            ))}
          </ul>
        </Card>
      ) : null}
    </>
  )
}

function TeacherDetail({ user }: { user: User }) {
  const { classes, timetable } = useData()
  const homeroomClasses = classes.filter((c) => c.homeroomTeacher === user.email)

  const taughtClasses = useMemo(() => {
    const ids = Array.from(
      new Set(timetable.filter((s) => s.teacher === user.fullName).map((s) => s.classId)),
    )
    return ids
      .map((id) => classes.find((c) => c.id === id))
      .filter((c): c is (typeof classes)[number] => Boolean(c))
      .sort((a, b) => a.id.localeCompare(b.id))
  }, [timetable, classes, user.fullName])

  // Get teacher's schedule from timetable
  const teacherSchedule = useMemo(() => {
    const slots = timetable.filter((s) => s.teacher === user.fullName)
    // Group by day
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    const grouped = new Map<string, typeof slots>()
    for (const day of days) {
      const daySlots = slots.filter((s) => s.day === day).sort((a, b) => {
        return a.period - b.period
      })
      if (daySlots.length > 0) {
        grouped.set(day, daySlots)
      }
    }
    return grouped
  }, [timetable, user.fullName])

  const totalSlots = useMemo(() => {
    return timetable.filter((s) => s.teacher === user.fullName).length
  }, [timetable, user.fullName])

  return (
    <>
      <Card title="Teaching Summary">
        <dl className="grid gap-4 sm:grid-cols-3 text-sm">
          <Detail label="Subject" value={user.subject ?? '—'} />
          <div>
            <dt className="text-xs font-semibold uppercase text-slate-500">Homeroom Classes</dt>
            <dd className="mt-1 font-medium text-slate-800">
              {homeroomClasses.length === 0
                ? '—'
                : homeroomClasses.map((c) => c.name).join(', ')}
            </dd>
          </div>
          <Detail label="Classes Teaching" value={String(taughtClasses.length)} />
          <Detail label="Weekly Slots" value={String(totalSlots)} />
        </dl>

        <div className="mt-4">
          <p className="text-xs font-semibold uppercase text-slate-500">Classes Teaching</p>
          {taughtClasses.length === 0 ? (
            <p className="mt-1 text-sm text-slate-500">No scheduled classes.</p>
          ) : (
            <ul className="mt-2 grid gap-2 sm:grid-cols-2">
              {taughtClasses.map((c) => (
                <li key={c.id}>
                  <Link
                    to={classDetailPath(c.id, user.subject)}
                    className="flex items-center justify-between rounded-lg border border-slate-200 px-3 py-2 hover:bg-slate-50"
                  >
                    <span>
                      <span className="block font-semibold text-indigo-600">{c.name}</span>
                      <span className="block text-xs text-slate-500">
                        {c.id} · Grade {c.grade}
                      </span>
                    </span>
                    <span aria-hidden className="text-slate-400">→</span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </div>
      </Card>

      <Card title="Weekly Schedule">
        {teacherSchedule.size === 0 ? (
          <p className="text-sm text-slate-500">No scheduled classes.</p>
        ) : (
          <div className="space-y-4">
            {Array.from(teacherSchedule.entries()).map(([day, slots]) => (
              <div key={day}>
                <h4 className="text-sm font-semibold text-slate-700 mb-2">{day}</h4>
                <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
                  {slots.map((slot, idx) => {
                    const slotClass = classes.find((c) => c.id === slot.classId)
                    return (
                      <div
                        key={`${day}-${idx}`}
                        className="border border-slate-200 rounded-lg px-3 py-2 bg-slate-50"
                      >
                        <p className="text-xs text-slate-500">
                          Period {slot.period} ({PERIOD_TIMES[slot.period]?.start ?? '00:00'} - {PERIOD_TIMES[slot.period]?.end ?? '00:00'})
                        </p>
                        <p className="font-semibold text-slate-800">{slot.subject}</p>
                        <p className="text-xs text-indigo-600">
                          {slotClass ? slotClass.name : slot.classId}
                        </p>
                        {slot.room && (
                          <p className="text-xs text-slate-500">Room: {slot.room}</p>
                        )}
                      </div>
                    )
                  })}
                </div>
              </div>
            ))}
          </div>
        )}
      </Card>
    </>
  )
}

function ParentDetail({ user, child }: { user: User; child?: User }) {
  return (
    <Card title="Linked Child">
      {child ? (
        <Link
          to={userDetailPath(child.email)}
          className="inline-flex items-center gap-3 rounded-lg border border-slate-200 px-3 py-2 hover:bg-slate-50"
        >
          <span className="flex h-9 w-9 items-center justify-center rounded-full bg-emerald-600 text-sm font-bold text-white">
            {child.fullName.charAt(0).toUpperCase()}
          </span>
          <span>
            <span className="block font-semibold text-slate-900">{child.fullName}</span>
            <span className="block text-xs text-slate-500">{child.email}</span>
          </span>
        </Link>
      ) : (
        <p className="text-sm text-slate-500">
          {user.childEmail
            ? `No student account found for ${user.childEmail}.`
            : 'No child account linked.'}
        </p>
      )}
    </Card>
  )
}
