import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Card } from '../../components/Card'
import { FormField } from '../../components/FormField'
import { Modal } from '../../components/Modal'
import { Tabs } from '../../components/Tabs'
import { useAuth } from '../../hooks/useAuth'
import { useData } from '../../hooks/useData'
import { useToast } from '../../hooks/useToast'
import { assignGradeToStudent, markStudentAsGraduated } from '../../services/api'
import { userDetailPath } from '../userDetailPath'
import { chatGroupDetailPath } from '../chatGroupDetailPath'
import { classDetailPath } from '../classDetailPath'
import { notificationDetailPath } from '../notificationDetailPath'
import type { ChatGroupType, Grade } from '../../types'

export function AdminDashboard() {
  const { users, classes } = useData()
  const navigate = useNavigate()
  const [activeView, setActiveView] = useState<'overview' | 'administration'>('overview')

  const students = useMemo(() => users.filter((u) => u.role === 'student'), [users])

  const classGradeMap = useMemo(() => {
    return new Map(classes.map((schoolClass) => [schoolClass.id, schoolClass.grade]))
  }, [classes])

  const counts = useMemo(() => {
    const byGrade = { 10: 0, 11: 0, 12: 0 } as Record<Grade, number>
    for (const student of students) {
      const grade = student.classId ? classGradeMap.get(student.classId) ?? student.grade : student.grade
      if (grade) byGrade[grade] += 1
    }

    const byClass = classes
      .map((schoolClass) => ({
        id: schoolClass.id,
        name: schoolClass.name,
        grade: schoolClass.grade,
        count: students.filter((student) => student.classId === schoolClass.id).length,
      }))
      .sort((a, b) => a.name.localeCompare(b.name))

    return {
      students: students.length,
      teachers: users.filter((u) => u.role === 'teacher').length,
      parents: users.filter((u) => u.role === 'parent').length,
      classes: classes.length,
      byGrade,
      byClass,
    }
  }, [users, classes, students, classGradeMap])

  return (
    <div className="space-y-4">
      <Card>
        <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Admin Workspace</h2>
            <p className="text-sm text-slate-500">Switch between dashboard analytics and administration tools.</p>
          </div>
          <div className="inline-flex rounded-lg border border-slate-200 p-1 bg-slate-50">
            <button
              type="button"
              onClick={() => setActiveView('overview')}
              className={`px-3 py-1.5 text-sm font-medium rounded-md ${
                activeView === 'overview' ? 'bg-white text-indigo-700 shadow-sm' : 'text-slate-600 hover:text-slate-800'
              }`}
            >
              Dashboard Overview
            </button>
            <button
              type="button"
              onClick={() => setActiveView('administration')}
              className={`px-3 py-1.5 text-sm font-medium rounded-md ${
                activeView === 'administration'
                  ? 'bg-white text-indigo-700 shadow-sm'
                  : 'text-slate-600 hover:text-slate-800'
              }`}
            >
              School Administration
            </button>
          </div>
        </div>
      </Card>

      {activeView === 'overview' ? (
        <>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <StatCard label="Students" value={counts.students} />
            <StatCard label="Teachers" value={counts.teachers} />
            <StatCard label="Parents" value={counts.parents} />
            <StatCard label="Classes" value={counts.classes} />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <Card title="Students by Grade">
              <ul className="space-y-2">
                {[10, 11, 12].map((grade) => (
                  <li
                    key={grade}
                    className="flex items-center justify-between rounded-lg border border-slate-200 px-3 py-2"
                  >
                    <span className="text-slate-700">Grade {grade}</span>
                    <span className="font-semibold text-indigo-700">{counts.byGrade[grade as Grade]}</span>
                  </li>
                ))}
              </ul>
            </Card>

            <Card title="Students by Class">
              {counts.byClass.length === 0 ? (
                <p className="text-sm text-slate-500">No classes found.</p>
              ) : (
                <ul className="space-y-2 max-h-80 overflow-auto pr-1">
                  {counts.byClass.map((item) => (
                    <li
                      key={item.id}
                      className="rounded-lg border border-slate-200"
                    >
                      <button
                        type="button"
                        onClick={() => navigate(classDetailPath(item.id))}
                        className="w-full px-3 py-2 flex items-center justify-between text-left hover:bg-slate-50 rounded-lg"
                      >
                        <span className="text-slate-700">
                          {item.name} <span className="text-slate-400">(Grade {item.grade})</span>
                        </span>
                        <span className="font-semibold text-indigo-700">{item.count}</span>
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </Card>
          </div>
        </>
      ) : (
        <Card title="School Administration">
          <Tabs
            tabs={[
              { id: 'students', label: 'Students', content: <ManageStudents /> },
              { id: 'grades', label: 'Grade Management', content: <ManageGrades /> },
              { id: 'teachers', label: 'Teachers', content: <ManageTeachers /> },
              { id: 'parents', label: 'Parents', content: <ManageParents /> },
              { id: 'classes', label: 'Classes', content: <ManageClasses /> },
              { id: 'news', label: 'News', content: <ManageNews /> },
              { id: 'notify', label: 'Notify Teachers', content: <NotifyTeachers /> },
              { id: 'chat', label: 'Chat Groups', content: <ManageChatGroups /> },
            ]}
          />
        </Card>
      )}
    </div>
  )
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm">
      <p className="text-sm text-slate-500">{label}</p>
      <p className="text-3xl font-bold text-indigo-600 mt-1">{value}</p>
    </div>
  )
}

interface StudentFormState {
  email: string
  fullName: string
  address: string
  phone: string
  age: string
  classId: string
  parentEmail: string
}

const STUDENT_INITIAL: StudentFormState = {
  email: '',
  fullName: '',
  address: '',
  phone: '',
  age: '',
  classId: '',
  parentEmail: '',
}

function ManageStudents() {
  const { users, classes, addUser, updateUser } = useData()
  const { push } = useToast()
  const navigate = useNavigate()
  const students = useMemo(() => users.filter((u) => u.role === 'student'), [users])

  const classLabelMap = useMemo(() => {
    return new Map(classes.map((schoolClass) => [schoolClass.id, `${schoolClass.name} (Grade ${schoolClass.grade})`]))
  }, [classes])

  const [searchTerm, setSearchTerm] = useState('')
  const [selectedClassFilter, setSelectedClassFilter] = useState<string>('all')
  const [sortBy, setSortBy] = useState<'name' | 'class' | 'email'>('name')
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('asc')
  const [page, setPage] = useState(1)
  const pageSize = 10

  const filteredAndSortedStudents = useMemo(() => {
    const normalizedSearch = searchTerm.trim().toLowerCase()

    const classFiltered =
      selectedClassFilter === 'all'
        ? students
        : students.filter((student) => (student.classId ?? 'unassigned') === selectedClassFilter)

    const filtered = normalizedSearch
      ? classFiltered.filter((student) => {
          const classLabel = student.classId ? classLabelMap.get(student.classId) ?? student.classId : 'Unassigned'
          return (
            student.fullName.toLowerCase().includes(normalizedSearch) ||
            student.email.toLowerCase().includes(normalizedSearch) ||
            classLabel.toLowerCase().includes(normalizedSearch)
          )
        })
      : classFiltered

    const sorted = [...filtered].sort((a, b) => {
      const aClass = a.classId ? classLabelMap.get(a.classId) ?? a.classId : 'Unassigned'
      const bClass = b.classId ? classLabelMap.get(b.classId) ?? b.classId : 'Unassigned'

      let left = ''
      let right = ''
      if (sortBy === 'name') {
        left = a.fullName
        right = b.fullName
      } else if (sortBy === 'email') {
        left = a.email
        right = b.email
      } else {
        left = aClass
        right = bClass
      }

      const result = left.localeCompare(right)
      return sortDirection === 'asc' ? result : -result
    })

    return sorted
  }, [students, selectedClassFilter, searchTerm, sortBy, sortDirection, classLabelMap])

  const totalPages = Math.max(1, Math.ceil(filteredAndSortedStudents.length / pageSize))

  useEffect(() => {
    setPage(1)
  }, [searchTerm, selectedClassFilter, sortBy, sortDirection])

  useEffect(() => {
    if (page > totalPages) setPage(totalPages)
  }, [page, totalPages])

  const pagedStudents = useMemo(() => {
    const start = (page - 1) * pageSize
    return filteredAndSortedStudents.slice(start, start + pageSize)
  }, [filteredAndSortedStudents, page])

  const [modalOpen, setModalOpen] = useState(false)
  const [form, setForm] = useState<StudentFormState>({
    ...STUDENT_INITIAL,
    classId: classes[0]?.id ?? '',
  })
  const [errors, setErrors] = useState<Partial<Record<keyof StudentFormState, string>>>({})

  const update = <K extends keyof StudentFormState>(key: K, value: StudentFormState[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }))

  const resetForm = () => {
    setForm({ ...STUDENT_INITIAL, classId: classes[0]?.id ?? '' })
    setErrors({})
  }

  const openModal = () => {
    resetForm()
    setModalOpen(true)
  }

  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const email = form.email.trim().toLowerCase()
    const next: Partial<Record<keyof StudentFormState, string>> = {}
    if (!form.email.trim()) next.email = 'Email is required.'
    else if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(form.email)) next.email = 'Enter a valid email.'
    else if (users.some((u) => u.email === email)) next.email = 'This email already exists.'
    if (!form.fullName.trim()) next.fullName = 'Full name is required.'
    if (!form.address.trim()) next.address = 'Address is required.'
    if (!form.phone.trim()) next.phone = 'Phone number is required.'
    else if (!/^[+\d][\d\s().-]{6,}$/.test(form.phone.trim()))
      next.phone = 'Enter a valid phone number.'
    if (!form.classId) next.classId = 'Assign a class.'
    const ageNumber = Number(form.age)
    if (!form.age) next.age = 'Age is required.'
    else if (Number.isNaN(ageNumber) || ageNumber < 5 || ageNumber > 100)
      next.age = 'Age must be 5-100.'
    if (form.parentEmail && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(form.parentEmail))
      next.parentEmail = 'Enter a valid parent email or leave blank.'

    setErrors(next)
    if (Object.keys(next).length > 0) return

    const selectedClass = classes.find((c) => c.id === form.classId)
    const grade = (selectedClass?.grade ?? 10) as Grade

    addUser({
      email,
      fullName: form.fullName.trim(),
      address: form.address.trim(),
      phone: form.phone.trim(),
      age: ageNumber,
      password: 'student123',
      role: 'student',
      classId: form.classId,
      grade,
    })

    // Link an existing parent account to this student.
    const nextParentEmail = form.parentEmail.trim().toLowerCase()
    if (nextParentEmail) {
      const parent = users.find((u) => u.email === nextParentEmail && u.role === 'parent')
      if (parent) updateUser(nextParentEmail, { childEmail: email })
    }

    setModalOpen(false)
    resetForm()
    push('success', `Student added. Login info sent to ${email}.`)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-slate-900">Students ({students.length})</h3>
        <button
          type="button"
          onClick={openModal}
          className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2 text-sm"
        >
          + Add Student
        </button>
      </div>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Add / Enroll Student"
        description="Login credentials are emailed to the student and parent."
      >
        <form onSubmit={submit} noValidate className="space-y-3">
          <FormField
            label="Email"
            name="studentEmail"
            type="email"
            value={form.email}
            onChange={(e) => update('email', e.target.value)}
            error={errors.email}
          />
          <FormField
            label="Full Name"
            name="studentName"
            value={form.fullName}
            onChange={(e) => update('fullName', e.target.value)}
            error={errors.fullName}
          />
          <FormField
            label="Address"
            name="studentAddress"
            value={form.address}
            onChange={(e) => update('address', e.target.value)}
            error={errors.address}
          />
          <FormField
            label="Phone Number"
            name="studentPhone"
            type="tel"
            value={form.phone}
            onChange={(e) => update('phone', e.target.value)}
            error={errors.phone}
          />
          <FormField
            label="Age"
            name="studentAge"
            type="number"
            min={5}
            max={100}
            value={form.age}
            onChange={(e) => update('age', e.target.value)}
            error={errors.age}
          />
          <FormField
            as="select"
            label="Class"
            name="studentClass"
            value={form.classId}
            onChange={(e) => update('classId', e.target.value)}
            error={errors.classId}
          >
            <option value="">Select a class</option>
            {classes.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name} (Grade {c.grade})
              </option>
            ))}
          </FormField>
          <FormField
            label="Parent Email (optional)"
            name="parentEmail"
            type="email"
            value={form.parentEmail}
            onChange={(e) => update('parentEmail', e.target.value)}
            error={errors.parentEmail}
            hint="Links an existing parent account to this student."
          />
          <div className="flex items-center gap-2 pt-2">
            <button
              type="submit"
              className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2"
            >
              Add Student
            </button>
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="border border-slate-300 text-slate-700 hover:bg-slate-100 font-semibold rounded-md px-4 py-2"
            >
              Cancel
            </button>
          </div>
        </form>
      </Modal>

      <Card>
        <div className="mb-3 grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-4">
          <FormField
            label="Search"
            name="searchStudents"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search by name, email, or class"
          />
          <FormField
            as="select"
            label="Class filter"
            name="classFilter"
            value={selectedClassFilter}
            onChange={(e) => setSelectedClassFilter(e.target.value)}
          >
            <option value="all">All classes</option>
            <option value="unassigned">Unassigned</option>
            {classes
              .slice()
              .sort((a, b) => a.name.localeCompare(b.name))
              .map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name} (Grade {c.grade})
                </option>
              ))}
          </FormField>
          <FormField
            as="select"
            label="Sort by"
            name="sortStudents"
            value={sortBy}
            onChange={(e) => setSortBy(e.target.value as 'name' | 'class' | 'email')}
          >
            <option value="name">Name</option>
            <option value="class">Class</option>
            <option value="email">Email</option>
          </FormField>
          <FormField
            as="select"
            label="Direction"
            name="sortDirection"
            value={sortDirection}
            onChange={(e) => setSortDirection(e.target.value as 'asc' | 'desc')}
          >
            <option value="asc">Ascending</option>
            <option value="desc">Descending</option>
          </FormField>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead>
              <tr className="text-left text-slate-500 border-b border-slate-200">
                <th className="py-2 pr-4">Name</th>
                <th className="py-2 pr-4">Class</th>
                <th className="py-2 pr-4">Email</th>
              </tr>
            </thead>
            <tbody>
              {filteredAndSortedStudents.length === 0 ? (
                <tr>
                  <td colSpan={3} className="py-3 text-slate-500">
                    No students found.
                  </td>
                </tr>
              ) : (
                pagedStudents.map((s) => (
                  <tr key={s.email} className="border-b border-slate-100">
                    <td className="py-2 pr-4 font-semibold">
                      <button
                        type="button"
                        onClick={() => navigate(userDetailPath(s.email))}
                        className="text-indigo-600 hover:text-indigo-800 hover:underline"
                      >
                        {s.fullName}
                      </button>
                    </td>
                    <td className="py-2 pr-4">
                      {s.classId ? classLabelMap.get(s.classId) ?? s.classId : 'Unassigned'}
                    </td>
                    <td className="py-2 pr-4 text-slate-600">{s.email}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {filteredAndSortedStudents.length > 0 && (
          <div className="mt-3 flex items-center justify-between text-sm text-slate-600">
            <span>
              Showing {(page - 1) * pageSize + 1}-{Math.min(page * pageSize, filteredAndSortedStudents.length)} of{' '}
              {filteredAndSortedStudents.length}
            </span>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page === 1}
                className="rounded border border-slate-300 px-3 py-1 disabled:opacity-50"
              >
                Previous
              </button>
              <span>
                Page {page}/{totalPages}
              </span>
              <button
                type="button"
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page === totalPages}
                className="rounded border border-slate-300 px-3 py-1 disabled:opacity-50"
              >
                Next
              </button>
            </div>
          </div>
        )}
      </Card>
    </div>
  )
}

function ManageGrades() {
  const { users, classes, timetable, updateUser } = useData()
  const { push } = useToast()
  const [activeTab, setActiveTab] = useState<'promotion' | 'assign'>('promotion')
  const [selectedGradeLevel, setSelectedGradeLevel] = useState<10 | 11 | 12 | 'graduate'>(10)
  const [selectedStudentEmail, setSelectedStudentEmail] = useState<string>('')
  const [promotionSourceGrade, setPromotionSourceGrade] = useState<'unassigned' | 10 | 11>(10)
  const [sourceClassFilter, setSourceClassFilter] = useState<string>('all')
  const [selectedTargetYear, setSelectedTargetYear] = useState<string>('')
  const [selectedTargetClassId, setSelectedTargetClassId] = useState<string>('')
  const [excludedPromotionEmails, setExcludedPromotionEmails] = useState<string[]>([])
  const [isPromoting, setIsPromoting] = useState(false)
  const [isAssigning, setIsAssigning] = useState(false)

  const students = users.filter((u) => u.role === 'student')
  const classGradeMap = new Map(classes.map((c) => [c.id, c.grade]))
  const getDerivedGrade = (student: (typeof students)[number]) =>
    student.classId ? classGradeMap.get(student.classId) ?? student.grade : student.grade
  const enrolledStudents = students.filter((s) => !!s.classId && classGradeMap.has(s.classId))
  const studentsByGrade = {
    10: enrolledStudents.filter((s) => getDerivedGrade(s) === 10),
    11: enrolledStudents.filter((s) => getDerivedGrade(s) === 11),
    12: enrolledStudents.filter((s) => getDerivedGrade(s) === 12),
  }

  const promotableStudents = useMemo(() => {
    return students.filter((student) => {
      const derivedGrade = getDerivedGrade(student)
      const canPromoteByGrade = derivedGrade === 10 || derivedGrade === 11
      const canPromoteFromUnassigned = !student.classId && !derivedGrade
      return canPromoteByGrade || canPromoteFromUnassigned
    })
  }, [students, classGradeMap])

  const promotableSet = useMemo(() => new Set(promotableStudents.map((s) => s.email)), [promotableStudents])

  const sourceClassOptions = useMemo(
    () => classes.filter((c) => c.grade === 10 || c.grade === 11).sort((a, b) => a.name.localeCompare(b.name)),
    [classes],
  )

  const expectedTargetGrade = promotionSourceGrade === 'unassigned' ? 10 : promotionSourceGrade === 10 ? 11 : 12

  const availableTargetYears = useMemo(
    () => Array.from(new Set(classes.map((c) => c.year))).sort((a, b) => b.localeCompare(a)),
    [classes],
  )

  const targetClassOptions = useMemo(() => {
    if (!selectedTargetYear) return []
    return classes
      .filter((c) => c.year === selectedTargetYear && c.grade === expectedTargetGrade)
      .sort((a, b) => a.name.localeCompare(b.name))
  }, [classes, selectedTargetYear, expectedTargetGrade])

  const selectedTargetClass = targetClassOptions.find((c) => c.id === selectedTargetClassId)
  const targetClassHasHomeroomTeacher = !!selectedTargetClass?.homeroomTeacher
  const targetClassHasRoom = !!selectedTargetClass && timetable.some((slot) => slot.classId === selectedTargetClass.id && !!slot.room)

  const filteredPromotionCandidates = useMemo(() => {
    return promotableStudents.filter((student) => {
      const grade = getDerivedGrade(student)
      const gradeMatch =
        promotionSourceGrade === 'unassigned' ? !student.classId && !grade : grade === promotionSourceGrade
      const classMatch = sourceClassFilter === 'all' ? true : student.classId === sourceClassFilter
      return gradeMatch && classMatch
    })
  }, [promotableStudents, promotionSourceGrade, sourceClassFilter])

  const selectedPromotionEmails = useMemo(() => {
    const excludedSet = new Set(excludedPromotionEmails)
    return filteredPromotionCandidates.filter((s) => !excludedSet.has(s.email)).map((s) => s.email)
  }, [filteredPromotionCandidates, excludedPromotionEmails])

  const isAllFilteredIncluded =
    filteredPromotionCandidates.length > 0 && selectedPromotionEmails.length === filteredPromotionCandidates.length

  const toggleStudentInclusion = (email: string) => {
    setExcludedPromotionEmails((prev) =>
      prev.includes(email) ? prev.filter((item) => item !== email) : [...prev, email],
    )
  }

  const toggleSelectAllFiltered = () => {
    setExcludedPromotionEmails((prev) => {
      const filteredSet = new Set(filteredPromotionCandidates.map((s) => s.email))

      if (isAllFilteredIncluded) {
        const merged = new Set(prev)
        filteredSet.forEach((email) => merged.add(email))
        return Array.from(merged)
      }

      return prev.filter((email) => !filteredSet.has(email))
    })
  }

  useEffect(() => {
    setExcludedPromotionEmails((prev) => prev.filter((email) => users.some((u) => u.email === email) && promotableSet.has(email)))
  }, [users, promotableSet])

  useEffect(() => {
    setExcludedPromotionEmails([])
  }, [promotionSourceGrade, sourceClassFilter])

  useEffect(() => {
    if (!selectedTargetYear && availableTargetYears.length > 0) {
      setSelectedTargetYear(availableTargetYears[0])
    }
  }, [selectedTargetYear, availableTargetYears])

  useEffect(() => {
    if (targetClassOptions.length === 0) {
      setSelectedTargetClassId('')
      return
    }
    if (!targetClassOptions.some((c) => c.id === selectedTargetClassId)) {
      setSelectedTargetClassId(targetClassOptions[0].id)
    }
  }, [targetClassOptions, selectedTargetClassId])

  const handlePromoteSelected = async () => {
    if (selectedPromotionEmails.length === 0) {
      push('info', 'Select at least one student to promote.')
      return
    }

    if (!selectedTargetClass) {
      push('error', 'Select a destination class for the new school year first.')
      return
    }

    if (!targetClassHasHomeroomTeacher) {
      push('error', 'Destination class must have a homeroom teacher assigned before promotion.')
      return
    }

    if (!targetClassHasRoom) {
      push('error', 'Destination class must have at least one timetable slot with room assigned before promotion.')
      return
    }

    if (!window.confirm(`Promote ${selectedPromotionEmails.length} selected student(s) to ${selectedTargetClass.name} (${selectedTargetClass.year})?`)) {
      return
    }

    setIsPromoting(true)
    try {
      let successCount = 0
      const failedStudents: string[] = []

      for (const email of selectedPromotionEmails) {
        const student = students.find((s) => s.email === email)
        const grade = student ? getDerivedGrade(student) : undefined
        const isUnassigned = !!student && !student.classId && !grade
        if (!student || (grade !== 10 && grade !== 11 && !isUnassigned)) {
          failedStudents.push(email)
          continue
        }

        const studentId = student.userId || student.email
        const nextGradeId = grade === 10 ? 2 : grade === 11 ? 3 : 1

        try {
          await assignGradeToStudent(studentId, nextGradeId)
          updateUser(student.email, { grade: nextGradeId === 1 ? 10 : nextGradeId === 2 ? 11 : 12, classId: selectedTargetClass.id })
          successCount += 1
        } catch {
          failedStudents.push(student.fullName)
        }
      }

      if (successCount > 0) {
        push('success', `Promoted ${successCount} student(s).`)
      }
      if (failedStudents.length > 0) {
        push('error', `Failed to promote ${failedStudents.length} student(s).`)
      }

      setExcludedPromotionEmails([])
    } catch (err) {
      push('error', 'Failed to promote selected students.')
      console.error(err)
    } finally {
      setIsPromoting(false)
    }
  }

  const handleAssignGrade = async () => {
    if (!selectedStudentEmail || !selectedGradeLevel) {
      push('info', 'Select a student and grade level.')
      return
    }
    const student = students.find((s) => s.email === selectedStudentEmail)
    if (!student) {
      push('error', 'Student not found.')
      return
    }
    setIsAssigning(true)
    try {
      const studentId = student.userId || student.email
      if (selectedGradeLevel === 'graduate') {
        if (getDerivedGrade(student) !== 12) {
          push('error', 'Only Grade 12 students can be marked as graduated.')
          return
        }
        if (!window.confirm(`Mark ${student.fullName} as graduated?`)) {
          return
        }
        await markStudentAsGraduated(studentId)
        push('success', `${student.fullName} marked as graduated.`)
      } else {
        if (!window.confirm(`Assign Grade ${selectedGradeLevel} to ${student.fullName}?`)) {
          return
        }
        const gradeId = selectedGradeLevel === 10 ? 1 : selectedGradeLevel === 11 ? 2 : 3
        await assignGradeToStudent(studentId, gradeId)
        push('success', `Grade ${selectedGradeLevel} assigned to ${student.fullName}.`)
      }
      setSelectedStudentEmail('')
    } catch (err) {
      push('error', selectedGradeLevel === 'graduate' ? 'Failed to mark student as graduated.' : 'Failed to assign grade.')
      console.error(err)
    } finally {
      setIsAssigning(false)
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex border-b border-slate-200 gap-1">
        <button
          onClick={() => setActiveTab('promotion')}
          className={`px-4 py-2 text-sm font-semibold ${
            activeTab === 'promotion'
              ? 'border-b-2 border-indigo-600 text-indigo-600'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          Year-End Promotion
        </button>
        <button
          onClick={() => setActiveTab('assign')}
          className={`px-4 py-2 text-sm font-semibold ${
            activeTab === 'assign'
              ? 'border-b-2 border-indigo-600 text-indigo-600'
              : 'text-slate-600 hover:text-slate-900'
          }`}
        >
          Assign Grade
        </button>
      </div>

      {activeTab === 'promotion' && (
        <Card title="Year-End Grade Promotion" description="Use rules to auto-select students, then only exclude exceptions.">
          <div className="space-y-4">
            <div className="bg-slate-50 border border-slate-200 rounded-md p-4">
              <h4 className="font-semibold text-slate-900 mb-2">Promotion Eligibility</h4>
              <ul className="space-y-1 text-sm text-slate-700">
                <li>Unassigned → Grade 10: <span className="font-semibold">{promotableStudents.filter((s) => !s.classId && !getDerivedGrade(s)).length} students</span></li>
                <li>Grade 10 → Grade 11: <span className="font-semibold">{studentsByGrade[10].length} students</span></li>
                <li>Grade 11 → Grade 12: <span className="font-semibold">{studentsByGrade[11].length} students</span></li>
                <li>Grade 12 students: <span className="text-amber-600">Not promoted (eligible for graduation)</span></li>
              </ul>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <FormField
                as="select"
                label="Source Grade"
                name="promotionSourceGrade"
                value={String(promotionSourceGrade)}
                onChange={(e) => {
                  const value = e.target.value
                  if (value === 'unassigned') {
                    setPromotionSourceGrade(value)
                    return
                  }
                  setPromotionSourceGrade(Number(value) as 10 | 11)
                }}
              >
                <option value="unassigned">Unassigned students (to Grade 10)</option>
                <option value="10">Grade 10 only</option>
                <option value="11">Grade 11 only</option>
              </FormField>
              <FormField
                as="select"
                label="Current Class"
                name="sourceClassFilter"
                value={sourceClassFilter}
                onChange={(e) => setSourceClassFilter(e.target.value)}
              >
                <option value="all">All classes</option>
                {sourceClassOptions.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name} (Grade {c.grade})
                  </option>
                ))}
              </FormField>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              <FormField
                as="select"
                label="Destination School Year"
                name="promotionTargetYear"
                value={selectedTargetYear}
                onChange={(e) => setSelectedTargetYear(e.target.value)}
              >
                {availableTargetYears.length === 0 ? (
                  <option value="">No school year available</option>
                ) : (
                  availableTargetYears.map((year) => (
                    <option key={year} value={year}>
                      {year}
                    </option>
                  ))
                )}
              </FormField>
              <FormField
                as="select"
                label="Destination Class"
                name="promotionTargetClass"
                value={selectedTargetClassId}
                onChange={(e) => setSelectedTargetClassId(e.target.value)}
              >
                {targetClassOptions.length === 0 ? (
                  <option value="">No class available for this year and grade</option>
                ) : (
                  targetClassOptions.map((c) => (
                    <option key={c.id} value={c.id}>
                      {c.name} (Grade {c.grade})
                    </option>
                  ))
                )}
              </FormField>
            </div>

            {selectedTargetClass && (
              <div className="rounded-md border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-700">
                <p>
                  Destination readiness: Teacher{' '}
                  <span className={targetClassHasHomeroomTeacher ? 'text-emerald-600 font-semibold' : 'text-rose-600 font-semibold'}>
                    {targetClassHasHomeroomTeacher ? 'assigned' : 'missing'}
                  </span>
                  {' '}| Room{' '}
                  <span className={targetClassHasRoom ? 'text-emerald-600 font-semibold' : 'text-rose-600 font-semibold'}>
                    {targetClassHasRoom ? 'assigned' : 'missing'}
                  </span>
                </p>
              </div>
            )}

            <div className="border border-slate-200 rounded-md">
              <div className="flex items-center justify-between border-b border-slate-200 px-3 py-2">
                <span className="text-sm font-medium text-slate-700">Review selection (exclude exceptions)</span>
                <button
                  type="button"
                  onClick={toggleSelectAllFiltered}
                  className="text-sm text-indigo-600 hover:text-indigo-800"
                >
                  {isAllFilteredIncluded ? 'Exclude All' : 'Include All'}
                </button>
              </div>
              <div className="max-h-64 overflow-auto px-3 py-2 space-y-2">
                {filteredPromotionCandidates.length === 0 ? (
                  <p className="text-sm text-slate-500">No promotable students match this filter.</p>
                ) : (
                  filteredPromotionCandidates.map((student) => {
                    const grade = getDerivedGrade(student)
                    const nextGrade = grade === 10 ? 11 : grade === 11 ? 12 : 10
                    const isIncluded = selectedPromotionEmails.includes(student.email)
                    const fromLabel = grade ? `G${grade}` : 'Unassigned'
                    const toLabel = `G${nextGrade}`
                    return (
                      <label key={student.email} className="flex items-center justify-between gap-3 rounded-md px-2 py-1.5 hover:bg-slate-50">
                        <span className="flex items-center gap-2">
                          <input
                            type="checkbox"
                            checked={isIncluded}
                            onChange={() => toggleStudentInclusion(student.email)}
                            className="h-4 w-4"
                          />
                          <span className="text-sm text-slate-700">
                            {student.fullName} <span className="text-slate-500">({student.email})</span>
                          </span>
                        </span>
                        <span className="text-xs text-slate-500">{fromLabel} → {toLabel}</span>
                      </label>
                    )
                  })
                )}
              </div>
            </div>

            <p className="text-xs text-slate-500">
              Included for promotion: {selectedPromotionEmails.length} / {filteredPromotionCandidates.length}
            </p>

            <button
              onClick={handlePromoteSelected}
              disabled={
                isPromoting ||
                selectedPromotionEmails.length === 0 ||
                !selectedTargetClass ||
                !targetClassHasHomeroomTeacher ||
                !targetClassHasRoom
              }
              className="bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-300 text-white font-semibold rounded-md px-4 py-2"
            >
              {isPromoting ? 'Promoting...' : `Promote Selected (${selectedPromotionEmails.length})`}
            </button>
          </div>
        </Card>
      )}

      {activeTab === 'assign' && (
        <Card title="Assign Grade / Graduate Student" description="Assign a grade level or mark Grade 12 students as graduated.">
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Select Student</label>
              <select
                value={selectedStudentEmail}
                onChange={(e) => setSelectedStudentEmail(e.target.value)}
                className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm"
              >
                <option value="">-- Select a student --</option>
                {students.map((s) => (
                  <option key={s.email} value={s.email}>
                    {s.fullName} ({s.email}) - Current: {getDerivedGrade(s) || 'Unassigned'}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Action</label>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                {([10, 11, 12] as const).map((grade) => (
                  <button
                    key={grade}
                    onClick={() => setSelectedGradeLevel(grade)}
                    className={`flex-1 py-2 font-semibold rounded-md border ${
                      selectedGradeLevel === grade
                        ? 'bg-indigo-600 border-indigo-600 text-white'
                        : 'border-slate-300 text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    Grade {grade}
                  </button>
                ))}
                <button
                  onClick={() => setSelectedGradeLevel('graduate')}
                  className={`flex-1 py-2 font-semibold rounded-md border ${
                    selectedGradeLevel === 'graduate'
                      ? 'bg-emerald-600 border-emerald-600 text-white'
                      : 'border-slate-300 text-slate-700 hover:bg-slate-50'
                  }`}
                >
                  Graduate
                </button>
              </div>
              {selectedGradeLevel === 'graduate' && (
                <p className="text-xs text-slate-500 mt-2">Only students currently in Grade 12 can be graduated.</p>
              )}
            </div>
            <button
              onClick={handleAssignGrade}
              disabled={isAssigning || !selectedStudentEmail}
              className={`${
                selectedGradeLevel === 'graduate'
                  ? 'bg-emerald-600 hover:bg-emerald-700'
                  : 'bg-indigo-600 hover:bg-indigo-700'
              } disabled:bg-slate-300 text-white font-semibold rounded-md px-4 py-2`}
            >
              {isAssigning
                ? selectedGradeLevel === 'graduate'
                  ? 'Marking...'
                  : 'Assigning...'
                : selectedGradeLevel === 'graduate'
                  ? 'Mark as Graduated'
                  : 'Assign Grade'}
            </button>
          </div>
        </Card>
      )}
    </div>
  )
}

interface TeacherFormState {
  email: string
  fullName: string
  address: string
  phone: string
  subject: string
}

const TEACHER_INITIAL: TeacherFormState = {
  email: '',
  fullName: '',
  address: '',
  phone: '',
  subject: '',
}

interface ParentFormState {
  email: string
  fullName: string
  address: string
  phone: string
  occupation: string
  childEmail: string
}

const PARENT_INITIAL: ParentFormState = {
  email: '',
  fullName: '',
  address: '',
  phone: '',
  occupation: '',
  childEmail: '',
}

function ManageTeachers() {
  const { users, subjects, addUser } = useData()
  const { push } = useToast()
  const navigate = useNavigate()
  const teachers = users.filter((u) => u.role === 'teacher')

  const [modalOpen, setModalOpen] = useState(false)
  const [form, setForm] = useState<TeacherFormState>({
    ...TEACHER_INITIAL,
    subject: subjects[0]?.name ?? '',
  })
  const [errors, setErrors] = useState<Partial<Record<keyof TeacherFormState, string>>>({})

  const update = <K extends keyof TeacherFormState>(key: K, value: TeacherFormState[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }))

  const resetForm = () => {
    setForm({ ...TEACHER_INITIAL, subject: subjects[0]?.name ?? '' })
    setErrors({})
  }

  const openModal = () => {
    resetForm()
    setModalOpen(true)
  }

  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const email = form.email.trim().toLowerCase()
    const next: Partial<Record<keyof TeacherFormState, string>> = {}
    if (!form.email.trim()) next.email = 'Email is required.'
    else if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(form.email)) next.email = 'Enter a valid email.'
    else if (users.some((u) => u.email === email)) next.email = 'This email already exists.'
    if (!form.fullName.trim()) next.fullName = 'Full name is required.'
    if (!form.address.trim()) next.address = 'Address is required.'
    if (!form.phone.trim()) next.phone = 'Phone number is required.'
    else if (!/^[+\d][\d\s().-]{6,}$/.test(form.phone.trim()))
      next.phone = 'Enter a valid phone number.'
    if (!form.subject) next.subject = 'Assign a subject.'

    setErrors(next)
    if (Object.keys(next).length > 0) return

    addUser({
      email,
      fullName: form.fullName.trim(),
      address: form.address.trim(),
      phone: form.phone.trim(),
      password: 'teacher123',
      role: 'teacher',
      subject: form.subject,
    })
    setModalOpen(false)
    resetForm()
    push('success', `Teacher added and assigned to ${form.subject}.`)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-slate-900">Teachers ({teachers.length})</h3>
        <button
          type="button"
          onClick={openModal}
          className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2 text-sm"
        >
          + Add Teacher
        </button>
      </div>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Add Subject Teacher"
      >
        <form onSubmit={submit} noValidate className="space-y-3">
          <FormField
            label="Email"
            name="teacherEmail"
            type="email"
            value={form.email}
            onChange={(e) => update('email', e.target.value)}
            error={errors.email}
          />
          <FormField
            label="Full Name"
            name="teacherName"
            value={form.fullName}
            onChange={(e) => update('fullName', e.target.value)}
            error={errors.fullName}
          />
          <FormField
            label="Address"
            name="teacherAddress"
            value={form.address}
            onChange={(e) => update('address', e.target.value)}
            error={errors.address}
          />
          <FormField
            label="Phone Number"
            name="teacherPhone"
            type="tel"
            value={form.phone}
            onChange={(e) => update('phone', e.target.value)}
            error={errors.phone}
          />
          <FormField
            as="select"
            label="Subject"
            name="teacherSubject"
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
          <div className="flex items-center gap-2 pt-2">
            <button
              type="submit"
              className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2"
            >
              Add Teacher
            </button>
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="border border-slate-300 text-slate-700 hover:bg-slate-100 font-semibold rounded-md px-4 py-2"
            >
              Cancel
            </button>
          </div>
        </form>
      </Modal>

      <Card>
        {teachers.length === 0 ? (
          <p className="text-sm text-slate-500">No teachers yet.</p>
        ) : (
          <ul className="space-y-2">
            {teachers.map((t) => (
              <li
                key={t.email}
                className="flex flex-wrap items-center justify-between gap-2 border border-slate-200 rounded-lg px-3 py-2"
              >
                <div>
                  <button
                    type="button"
                    onClick={() => navigate(userDetailPath(t.email))}
                    className="font-semibold text-indigo-600 hover:text-indigo-800 hover:underline"
                  >
                    {t.fullName}
                  </button>
                  <p className="text-xs text-slate-500">{t.email}</p>
                </div>
                <div className="flex items-center gap-2">
                  <span className="inline-flex items-center rounded-full bg-indigo-100 text-indigo-700 px-2 py-0.5 text-xs font-semibold">
                    {t.subject}
                  </span>
                </div>
              </li>
            ))}
          </ul>
        )}
      </Card>
    </div>
  )
}

interface ClassFormState {
  id: string
  name: string
  grade: string
  year: string
  homeroomTeacher: string
}

function getAcademicYearLabel(startYear: number) {
  return `${startYear}-${startYear + 1}`
}

function getDefaultAcademicYearLabel() {
  const now = new Date()
  const year = now.getFullYear()
  const month = now.getMonth() + 1
  // School year typically starts around Aug/Sep.
  const startYear = month >= 8 ? year : year - 1
  return getAcademicYearLabel(startYear)
}

const CLASS_INITIAL: ClassFormState = {
  id: '',
  name: '',
  grade: '10',
  year: getDefaultAcademicYearLabel(),
  homeroomTeacher: '',
}

function ManageParents() {
  const { users, addUser } = useData()
  const { push } = useToast()
  const navigate = useNavigate()
  const parents = users.filter((u) => u.role === 'parent')
  const students = users.filter((u) => u.role === 'student')

  const [modalOpen, setModalOpen] = useState(false)
  const [form, setForm] = useState<ParentFormState>(PARENT_INITIAL)
  const [errors, setErrors] = useState<Partial<Record<keyof ParentFormState, string>>>({})

  const update = <K extends keyof ParentFormState>(key: K, value: ParentFormState[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }))

  const resetForm = () => {
    setForm(PARENT_INITIAL)
    setErrors({})
  }

  const openModal = () => {
    resetForm()
    setModalOpen(true)
  }

  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const email = form.email.trim().toLowerCase()
    const next: Partial<Record<keyof ParentFormState, string>> = {}
    if (!form.email.trim()) next.email = 'Email is required.'
    else if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(form.email)) next.email = 'Enter a valid email.'
    else if (users.some((u) => u.email === email)) next.email = 'This email already exists.'
    if (!form.fullName.trim()) next.fullName = 'Full name is required.'
    if (!form.address.trim()) next.address = 'Address is required.'
    if (!form.phone.trim()) next.phone = 'Phone number is required.'
    else if (!/^[+\d][\d\s().-]{6,}$/.test(form.phone.trim()))
      next.phone = 'Enter a valid phone number.'
    if (form.childEmail) {
      const childEmailNorm = form.childEmail.trim().toLowerCase()
      if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(childEmailNorm))
        next.childEmail = 'Enter a valid student email or leave blank.'
      else if (!students.some((s) => s.email === childEmailNorm))
        next.childEmail = 'No student found with this email.'
    }

    setErrors(next)
    if (Object.keys(next).length > 0) return

    const childEmailNorm = form.childEmail.trim().toLowerCase() || undefined

    addUser({
      email,
      fullName: form.fullName.trim(),
      address: form.address.trim(),
      phone: form.phone.trim(),
      password: 'parent123',
      role: 'parent',
      childEmail: childEmailNorm,
    })

    setModalOpen(false)
    resetForm()
    push('success', `Parent added. Login info sent to ${email}.`)
  }

  // Find linked child for each parent
  const getLinkedChild = (parent: typeof parents[0]) => {
    if (parent.childEmail) {
      return students.find((s) => s.email === parent.childEmail)
    }
    return undefined
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-slate-900">Parents ({parents.length})</h3>
        <button
          type="button"
          onClick={openModal}
          className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2 text-sm"
        >
          + Add Parent
        </button>
      </div>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Add Parent"
        description="Login credentials are emailed to the parent."
      >
        <form onSubmit={submit} noValidate className="space-y-3">
          <FormField
            label="Email"
            name="parentEmail"
            type="email"
            value={form.email}
            onChange={(e) => update('email', e.target.value)}
            error={errors.email}
          />
          <FormField
            label="Full Name"
            name="parentName"
            value={form.fullName}
            onChange={(e) => update('fullName', e.target.value)}
            error={errors.fullName}
          />
          <FormField
            label="Address"
            name="parentAddress"
            value={form.address}
            onChange={(e) => update('address', e.target.value)}
            error={errors.address}
          />
          <FormField
            label="Phone Number"
            name="parentPhone"
            type="tel"
            value={form.phone}
            onChange={(e) => update('phone', e.target.value)}
            error={errors.phone}
          />
          <FormField
            label="Occupation (optional)"
            name="parentOccupation"
            value={form.occupation}
            onChange={(e) => update('occupation', e.target.value)}
          />
          <FormField
            as="select"
            label="Link to Student (optional)"
            name="parentChildEmail"
            value={form.childEmail}
            onChange={(e) => update('childEmail', e.target.value)}
            error={errors.childEmail}
            hint="Link this parent to an existing student."
          >
            <option value="">Select a student</option>
            {students.map((s) => (
              <option key={s.email} value={s.email}>
                {s.fullName} ({s.classId || 'No class'})
              </option>
            ))}
          </FormField>
          <div className="flex items-center gap-2 pt-2">
            <button
              type="submit"
              className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2"
            >
              Add Parent
            </button>
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="border border-slate-300 text-slate-700 hover:bg-slate-100 font-semibold rounded-md px-4 py-2"
            >
              Cancel
            </button>
          </div>
        </form>
      </Modal>

      <Card>
        {parents.length === 0 ? (
          <p className="text-sm text-slate-500">No parents yet.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="text-left text-slate-500 border-b border-slate-200">
                  <th className="py-2 pr-4">Name</th>
                  <th className="py-2 pr-4">Phone</th>
                  <th className="py-2 pr-4">Linked Child</th>
                  <th className="py-2 pr-4">Email</th>
                </tr>
              </thead>
              <tbody>
                {parents.map((p) => {
                  const child = getLinkedChild(p)
                  return (
                    <tr key={p.email} className="border-b border-slate-100">
                      <td className="py-2 pr-4 font-semibold">
                        <button
                          type="button"
                          onClick={() => navigate(userDetailPath(p.email))}
                          className="text-indigo-600 hover:text-indigo-800 hover:underline"
                        >
                          {p.fullName}
                        </button>
                      </td>
                      <td className="py-2 pr-4 text-slate-600">{p.phone || '—'}</td>
                      <td className="py-2 pr-4">
                        {child ? (
                          <button
                            type="button"
                            onClick={() => navigate(userDetailPath(child.email))}
                            className="text-indigo-600 hover:text-indigo-800 hover:underline"
                          >
                            {child.fullName}
                          </button>
                        ) : (
                          <span className="text-slate-400">Not linked</span>
                        )}
                      </td>
                      <td className="py-2 pr-4 text-slate-600">{p.email}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  )
}

function ManageClasses() {
  const { classes, users, addClass } = useData()
  const { push } = useToast()
  const navigate = useNavigate()
  const teachers = users.filter((u) => u.role === 'teacher')
  const currentAcademicYear = getDefaultAcademicYearLabel()
  const nextAcademicYear = useMemo(() => {
    const startYear = Number(currentAcademicYear.split('-')[0])
    return getAcademicYearLabel(startYear + 1)
  }, [currentAcademicYear])

  const studentsByClass = useMemo(() => {
    const map = new Map<string, number>()
    for (const u of users) {
      if (u.role === 'student' && u.classId) {
        map.set(u.classId, (map.get(u.classId) ?? 0) + 1)
      }
    }
    return map
  }, [users])

  const [modalOpen, setModalOpen] = useState(false)
  const [form, setForm] = useState<ClassFormState>(CLASS_INITIAL)
  const [errors, setErrors] = useState<Partial<Record<keyof ClassFormState, string>>>({})

  const update = <K extends keyof ClassFormState>(key: K, value: ClassFormState[K]) =>
    setForm((prev) => ({ ...prev, [key]: value }))

  const resetForm = () => {
    setForm(CLASS_INITIAL)
    setErrors({})
  }

  const openModal = () => {
    resetForm()
    setModalOpen(true)
  }

  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const id = form.id.trim()
    const next: Partial<Record<keyof ClassFormState, string>> = {}
    if (!id) next.id = 'Class ID is required.'
    else if (classes.some((c) => c.id.toLowerCase() === id.toLowerCase()))
      next.id = 'This class ID already exists.'
    if (!form.name.trim()) next.name = 'Class name is required.'
    if (!form.year.trim()) next.year = 'Academic year is required.'

    setErrors(next)
    if (Object.keys(next).length > 0) return

    const grade = Number(form.grade) as Grade
    addClass({
      id,
      name: form.name.trim(),
      grade,
      year: form.year.trim(),
      homeroomTeacher: form.homeroomTeacher || undefined,
    })
    setModalOpen(false)
    resetForm()
    push('success', `Class ${id} created.`)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-slate-900">Classes ({classes.length})</h3>
        <button
          type="button"
          onClick={openModal}
          className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2 text-sm"
        >
          + Create Class
        </button>
      </div>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Create Class"
      >
        <form onSubmit={submit} noValidate className="space-y-3">
          <FormField
            label="Class ID"
            name="classId"
            value={form.id}
            onChange={(e) => update('id', e.target.value)}
            error={errors.id}
            hint="Short code, e.g. 10A1."
          />
          <FormField
            label="Class Name"
            name="className"
            value={form.name}
            onChange={(e) => update('name', e.target.value)}
            error={errors.name}
          />
          <FormField
            as="select"
            label="Grade"
            name="classGrade"
            value={form.grade}
            onChange={(e) => update('grade', e.target.value)}
          >
            <option value="10">Grade 10</option>
            <option value="11">Grade 11</option>
            <option value="12">Grade 12</option>
          </FormField>
          <FormField
            label="Academic Year"
            name="classYear"
            value={form.year}
            onChange={(e) => update('year', e.target.value)}
            error={errors.year}
          />
          <div className="flex items-center gap-2 -mt-1">
            <button
              type="button"
              onClick={() => update('year', currentAcademicYear)}
              className="text-xs rounded border border-slate-300 px-2 py-1 text-slate-700 hover:bg-slate-50"
            >
              Use {currentAcademicYear}
            </button>
            <button
              type="button"
              onClick={() => update('year', nextAcademicYear)}
              className="text-xs rounded border border-slate-300 px-2 py-1 text-slate-700 hover:bg-slate-50"
            >
              Use {nextAcademicYear}
            </button>
          </div>
          <FormField
            as="select"
            label="Homeroom Teacher (optional)"
            name="classHomeroom"
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
          <div className="flex items-center gap-2 pt-2">
            <button
              type="submit"
              className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2"
            >
              Create Class
            </button>
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="border border-slate-300 text-slate-700 hover:bg-slate-100 font-semibold rounded-md px-4 py-2"
            >
              Cancel
            </button>
          </div>
        </form>
      </Modal>

      <Card>
        {classes.length === 0 ? (
          <p className="text-sm text-slate-500">No classes yet.</p>
        ) : (
          <ul className="space-y-2">
            {classes.map((c) => {
              const homeroom = users.find((u) => u.email === c.homeroomTeacher)
              return (
                <li
                  key={c.id}
                  className="flex flex-wrap items-start justify-between gap-2 border border-slate-200 rounded-lg px-3 py-2"
                >
                  <div>
                    <p>
                      <button
                        type="button"
                        onClick={() => navigate(classDetailPath(c.id))}
                        className="font-semibold text-indigo-600 hover:text-indigo-800 hover:underline"
                      >
                        {c.name}
                      </button>{' '}
                      <span className="inline-flex items-center rounded-full bg-indigo-100 text-indigo-700 px-2 py-0.5 text-xs font-semibold">
                        Grade {c.grade}
                      </span>
                    </p>
                    <p className="text-xs text-slate-500 mt-0.5">
                      {c.id} · {c.year} · {studentsByClass.get(c.id) ?? 0} student(s)
                    </p>
                    <p className="text-xs text-slate-500">
                      Homeroom: {homeroom ? homeroom.fullName : 'Unassigned'}
                    </p>
                  </div>
                  <span aria-hidden className="text-slate-400">→</span>
                </li>
              )
            })}
          </ul>
        )}
      </Card>
    </div>
  )
}

interface NewsFormState {
  title: string
  category: string
  body: string
}

const NEWS_INITIAL: NewsFormState = { title: '', category: 'Announcement', body: '' }

function ManageNews() {
  const { news, addNews, updateNews, removeNews } = useData()
  const { currentUser } = useAuth()
  const { push } = useToast()

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [form, setForm] = useState<NewsFormState>(NEWS_INITIAL)
  const [errors, setErrors] = useState<Partial<Record<keyof NewsFormState, string>>>({})

  const resetForm = () => {
    setForm(NEWS_INITIAL)
    setErrors({})
    setEditingId(null)
  }

  const openModal = () => {
    resetForm()
    setModalOpen(true)
  }

  const openEdit = (item: typeof news[0]) => {
    setEditingId(item.id)
    setForm({ title: item.title, category: item.category, body: item.body })
    setErrors({})
    setModalOpen(true)
  }

  const handleDelete = (id: number, title: string) => {
    if (!window.confirm(`Delete news "${title}"?`)) return
    removeNews(id)
    push('success', 'News deleted.')
  }

  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    const next: Partial<Record<keyof NewsFormState, string>> = {}
    if (!form.title.trim()) next.title = 'Title is required.'
    if (!form.body.trim()) next.body = 'Body is required.'
    setErrors(next)
    if (Object.keys(next).length > 0) return

    if (editingId !== null) {
      updateNews(editingId, {
        title: form.title.trim(),
        body: form.body.trim(),
        category: form.category,
      })
      push('success', 'News updated.')
    } else {
      addNews({
        title: form.title.trim(),
        body: form.body.trim(),
        category: form.category,
        author: currentUser?.fullName ?? 'Admin',
        date: new Date().toISOString().slice(0, 10),
      })
      push('success', 'News published.')
    }
    setModalOpen(false)
    resetForm()
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-slate-900">News ({news.length})</h3>
        <button
          type="button"
          onClick={openModal}
          className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2 text-sm"
        >
          + Post News
        </button>
      </div>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title={editingId !== null ? 'Edit News' : 'Post School News'}
      >
        <form onSubmit={submit} noValidate className="space-y-3">
          <FormField
            label="Title"
            name="newsTitle"
            value={form.title}
            onChange={(e) => setForm((p) => ({ ...p, title: e.target.value }))}
            error={errors.title}
          />
          <FormField
            as="select"
            label="Category"
            name="newsCategory"
            value={form.category}
            onChange={(e) => setForm((p) => ({ ...p, category: e.target.value }))}
          >
            <option>Announcement</option>
            <option>Event</option>
            <option>Notice</option>
          </FormField>
          <FormField
            as="textarea"
            label="Body"
            name="newsBody"
            rows={4}
            value={form.body}
            onChange={(e) => setForm((p) => ({ ...p, body: e.target.value }))}
            error={errors.body}
          />
          <div className="flex items-center gap-2 pt-2">
            <button
              type="submit"
              className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2"
            >
              {editingId !== null ? 'Save Changes' : 'Publish'}
            </button>
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="border border-slate-300 text-slate-700 hover:bg-slate-100 font-semibold rounded-md px-4 py-2"
            >
              Cancel
            </button>
          </div>
        </form>
      </Modal>

      <Card>
        {news.length === 0 ? (
          <p className="text-sm text-slate-500">No news published yet.</p>
        ) : (
          <ul className="space-y-3">
            {news.map((item) => (
              <li key={item.id} className="border border-slate-200 rounded-lg px-3 py-2">
                <div className="flex items-center justify-between gap-2">
                  <p className="font-semibold text-slate-900">{item.title}</p>
                  <div className="flex items-center gap-2">
                    <span className="text-xs rounded-full bg-slate-100 text-slate-600 px-2 py-0.5">
                      {item.category}
                    </span>
                    <button
                      type="button"
                      onClick={() => openEdit(item)}
                      className="text-xs text-indigo-600 hover:text-indigo-800 hover:underline"
                    >
                      Edit
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDelete(item.id, item.title)}
                      className="text-xs text-red-600 hover:text-red-800 hover:underline"
                    >
                      Delete
                    </button>
                  </div>
                </div>
                <p className="text-sm text-slate-600 mt-1">{item.body}</p>
                <p className="text-xs text-slate-400 mt-1">
                  {item.date} · {item.author}
                </p>
              </li>
            ))}
          </ul>
        )}
      </Card>
    </div>
  )
}

function NotifyTeachers() {
  const { addNotification, notifications } = useData()
  const { currentUser } = useAuth()
  const { push } = useToast()
  const [modalOpen, setModalOpen] = useState(false)
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [error, setError] = useState('')

  const teacherNotifications = notifications.filter((n) => n.audience === 'teacher')

  const resetForm = () => {
    setTitle('')
    setBody('')
    setError('')
  }

  const openModal = () => {
    resetForm()
    setModalOpen(true)
  }

  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!title.trim() || !body.trim()) {
      setError('Title and message are required.')
      return
    }
    setError('')
    addNotification({
      title: title.trim(),
      body: body.trim(),
      audience: 'teacher',
      sender: currentUser?.fullName ?? 'Admin',
      date: new Date().toISOString().slice(0, 10),
    })
    setModalOpen(false)
    resetForm()
    push('success', 'Notification sent to all teachers.')
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-slate-900">
          Teacher Notifications ({teacherNotifications.length})
        </h3>
        <button
          type="button"
          onClick={openModal}
          className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2 text-sm"
        >
          + Send Notification
        </button>
      </div>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Send Notification to Teachers"
      >
        <form onSubmit={submit} noValidate className="space-y-3">
          <FormField
            label="Title"
            name="notifyTitle"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            error={error && !title.trim() ? error : undefined}
          />
          <FormField
            as="textarea"
            label="Message"
            name="notifyBody"
            rows={4}
            value={body}
            onChange={(e) => setBody(e.target.value)}
            error={error && !body.trim() ? error : undefined}
          />
          <div className="flex items-center gap-2 pt-2">
            <button
              type="submit"
              className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2"
            >
              Send
            </button>
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="border border-slate-300 text-slate-700 hover:bg-slate-100 font-semibold rounded-md px-4 py-2"
            >
              Cancel
            </button>
          </div>
        </form>
      </Modal>

      <Card>
        {teacherNotifications.length === 0 ? (
          <p className="text-sm text-slate-500">No notifications sent yet.</p>
        ) : (
          <ul className="space-y-2">
            {teacherNotifications.map((n) => (
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
    </div>
  )
}

interface ChatGroupFormState {
  classId: string
  type: ChatGroupType
}

const GROUP_TYPE_LABELS: Record<ChatGroupType, string> = {
  'student-teacher': 'Students & Teachers',
  'parent-teacher': 'Parents & Teachers',
}

const GROUP_TYPE_SUFFIX: Record<ChatGroupType, string> = {
  'student-teacher': 'st',
  'parent-teacher': 'pt',
}

function ManageChatGroups() {
  const { classes, chatGroups, addChatGroup, users } = useData()
  const { push } = useToast()

  const [modalOpen, setModalOpen] = useState(false)
  const [form, setForm] = useState<ChatGroupFormState>({
    classId: classes[0]?.id ?? '',
    type: 'student-teacher',
  })
  const [createError, setCreateError] = useState('')

  // Calculate member counts for each chat group
  const getMemberCount = (group: typeof chatGroups[0]) => {
    const classStudents = users.filter((u) => u.role === 'student' && u.classId === group.classId)
    const teachers = users.filter((u) => u.role === 'teacher')
    
    if (group.type === 'student-teacher') {
      return classStudents.length + teachers.length
    } else {
      // parent-teacher: count parents of students in this class
      const studentEmails = new Set(classStudents.map((s) => s.email))
      const parents = users.filter(
        (u) => u.role === 'parent' && u.childEmail && studentEmails.has(u.childEmail)
      )
      return parents.length + teachers.length
    }
  }

  // Get groups count per class
  const getClassGroupsCount = (classId: string) => {
    return chatGroups.filter((g) => g.classId === classId).length
  }

  const openModal = () => {
    setForm({ classId: classes[0]?.id ?? '', type: 'student-teacher' })
    setCreateError('')
    setModalOpen(true)
  }

  const submit = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (!form.classId) {
      setCreateError('Select a class.')
      return
    }
    const schoolClass = classes.find((c) => c.id === form.classId)
    if (!schoolClass) {
      setCreateError('Invalid class.')
      return
    }
    
    // Check if this class already has 2 groups
    const existingGroups = chatGroups.filter((g) => g.classId === form.classId)
    if (existingGroups.length >= 2) {
      setCreateError('This class already has the maximum of 2 chat groups.')
      return
    }
    
    // Check if this specific type already exists for this class
    if (existingGroups.some((g) => g.type === form.type)) {
      setCreateError(`A ${GROUP_TYPE_LABELS[form.type]} group already exists for this class.`)
      return
    }
    
    const id = `${form.classId}-${schoolClass.year}-${GROUP_TYPE_SUFFIX[form.type]}`
    const name = `${schoolClass.name} ${GROUP_TYPE_LABELS[form.type]}`
    
    setCreateError('')
    addChatGroup({
      id,
      name,
      classId: form.classId,
      year: schoolClass.year,
      type: form.type,
    })
    setModalOpen(false)
    push('success', `Chat group created for ${schoolClass.name}.`)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-slate-900">Chat Groups ({chatGroups.length})</h3>
        <button
          type="button"
          onClick={openModal}
          className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2 text-sm"
        >
          + Create Group
        </button>
      </div>

      <Modal
        open={modalOpen}
        onClose={() => setModalOpen(false)}
        title="Create Chat Group"
        description="Each class can have up to 2 groups: one for students & teachers, one for parents & teachers."
      >
        <form onSubmit={submit} noValidate className="space-y-3">
          <FormField
            as="select"
            label="Class"
            name="chatGroupClass"
            value={form.classId}
            onChange={(e) => setForm((p) => ({ ...p, classId: e.target.value }))}
            error={createError && !form.classId ? createError : undefined}
            hint={form.classId ? `${getClassGroupsCount(form.classId)}/2 groups created` : undefined}
          >
            <option value="">Select a class</option>
            {classes.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name} (Grade {c.grade}, {c.year})
              </option>
            ))}
          </FormField>
          <FormField
            as="select"
            label="Group Type"
            name="chatGroupType"
            value={form.type}
            onChange={(e) => setForm((p) => ({ ...p, type: e.target.value as ChatGroupType }))}
            error={createError && form.classId ? createError : undefined}
          >
            <option value="student-teacher">Students &amp; Teachers</option>
            <option value="parent-teacher">Parents &amp; Teachers</option>
          </FormField>
          <div className="flex items-center gap-2 pt-2">
            <button
              type="submit"
              className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2"
            >
              Create Group
            </button>
            <button
              type="button"
              onClick={() => setModalOpen(false)}
              className="border border-slate-300 text-slate-700 hover:bg-slate-100 font-semibold rounded-md px-4 py-2"
            >
              Cancel
            </button>
          </div>
        </form>
      </Modal>

      <Card>
        {chatGroups.length === 0 ? (
          <p className="text-sm text-slate-500">No chat groups yet.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead>
                <tr className="text-left text-slate-500 border-b border-slate-200">
                  <th className="py-2 pr-4">Name</th>
                  <th className="py-2 pr-4">Class</th>
                  <th className="py-2 pr-4">Type</th>
                  <th className="py-2 pr-4">Members</th>
                </tr>
              </thead>
              <tbody>
                {chatGroups.map((g) => (
                  <tr key={g.id} className="border-b border-slate-100">
                    <td className="py-2 pr-4">
                      <Link
                        to={chatGroupDetailPath(g.id)}
                        className="font-semibold text-indigo-600 hover:text-indigo-800 hover:underline"
                      >
                        {g.name}
                      </Link>
                    </td>
                    <td className="py-2 pr-4 text-slate-600">
                      {g.classId} · {g.year}
                    </td>
                    <td className="py-2 pr-4">
                      <span
                        className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-semibold ${
                          g.type === 'student-teacher'
                            ? 'bg-indigo-100 text-indigo-700'
                            : 'bg-amber-100 text-amber-700'
                        }`}
                      >
                        {GROUP_TYPE_LABELS[g.type]}
                      </span>
                    </td>
                    <td className="py-2 pr-4 text-slate-600">{getMemberCount(g)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  )
}

