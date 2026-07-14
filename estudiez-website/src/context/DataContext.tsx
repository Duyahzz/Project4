import { createContext, useCallback, useEffect, useMemo, useRef, useState } from 'react'
import type { ReactNode } from 'react'
import type {
  AttendanceRecord,
  AttendanceStatus,
  ChatGroup,
  ChatMessage,
  Exam,
  Grade,
  Helpline,
  NewsItem,
  NotificationItem,
  ProgressDetail,
  Resource,
  RevisionClass,
  SchoolClass,
  ScoreDetail,
  Semester,
  Subject,
  TestEvaluation,
  TimetableSlot,
  User,
} from '../types'
import type { DayOfWeek } from '../types'
import {
  createLessonSession,
  recordAttendance,
  getLessonsByClass,
  deleteApiClass,
  deleteApiUser,
  deleteApiNotification as deleteApiNotificationApi,
  getAssessments,
  createApiAssessment,
  getClasses,
  getClassEnrollments,
  getChatGroups,
  getChatMessages,
  getContacts,
  getMarksByAssessment,
  getAllLessons,
  getSemesters,
  getAllNews,
  getAllAttendance,
  getNotifications,
  getParentLinks,
  getParents,
  getResources,
  getStudents,
  getTeachers,
  getTimetable,
  createApiTimetable,
  updateApiTimetable,
  deleteApiTimetable,
  getUsers,
  GRADE_MAP,
  mapApiAssessmentToExam,
  mapApiChatGroup,
  mapApiChatMessage,
  mapApiClass,
  mapApiContact,
  mapApiMarkToScore,
  mapApiNewsPost,
  mapApiNotification,
  mapApiStudyResource,
  mapApiTimetableSlot,
  mapApiUsersToFrontend,
  SUBJECT_ID_MAP,
  SEMESTER_ID_MAP,
  YEAR_MAP,
  getSchoolYears,
  saveMarkApi,
  sendChatMessage,
  type ApiAssessment,
  type ApiSchoolYear,
  type ApiAttendanceRecord,
  type ApiChatGroup,
  type ApiChatMessage,
  type ApiLessonSession,
  type ApiMark,
} from '../services/api'
import { SEED_SEMESTERS, SEED_SUBJECTS } from '../services/seed'

interface DataContextValue {
  loading: boolean
  error: string | null
  users: User[]
  classes: SchoolClass[]
  schoolYears: ApiSchoolYear[]
  subjects: Subject[]
  semesters: Semester[]
  exams: Exam[]
  scores: ScoreDetail[]
  progress: ProgressDetail[]
  attendance: AttendanceRecord[]
  timetable: TimetableSlot[]
  resources: Resource[]
  revisionClasses: RevisionClass[]
  evaluations: TestEvaluation[]
  news: NewsItem[]
  notifications: NotificationItem[]
  chatGroups: ChatGroup[]
  chatMessages: ChatMessage[]
  helplines: Helpline[]
  addUser: (user: User) => void
  updateUser: (email: string, patch: Partial<Omit<User, 'email' | 'role'>>) => User | null
  deleteUser: (email: string) => void
  addClass: (schoolClass: SchoolClass) => void
  updateClass: (id: string, patch: Partial<Omit<SchoolClass, 'id'>>) => void
  deleteClass: (id: string) => void
  addSemester: (semester: Semester) => void
  updateSemester: (id: string, patch: Partial<Omit<Semester, 'id'>>) => void
  deleteSemester: (id: string) => void
  addExam: (exam: Omit<Exam, 'id'>, teacherEmail: string) => Promise<void>
  updateExam: (id: number, patch: Partial<Omit<Exam, 'id'>>) => void
  deleteExam: (id: number) => void
  addScore: (score: Omit<ScoreDetail, 'id'>) => void
  addProgress: (entry: Omit<ProgressDetail, 'id'>) => void
  addAttendance: (record: Omit<AttendanceRecord, 'id'>) => void
  saveAttendanceBatch: (
    classId: string,
    subject: string,
    date: string,
    period: number,
    teacherEmail: string,
    records: { studentEmail: string; status: AttendanceStatus; note: string }[]
  ) => Promise<void>
  saveMarksAndEvaluationsBatch: (
    examId: number,
    classId: string,
    subject: string,
    teacherEmail: string,
    records: {
      studentEmail: string
      score: number
      evaluation?: {
        performanceLevel: 'excellent' | 'good' | 'average' | 'below-average' | 'poor'
        topicsMastered?: string
        topicsToImprove?: string
        studyHabits: 'consistent' | 'irregular' | 'needs-work'
        teacherNotes?: string
        strengths: string
        weaknesses: string
        suggestedPath: string
        teacher: string
      }
    }[]
  ) => Promise<void>
  addResource: (resource: Omit<Resource, 'id'>) => void
  addRevisionClass: (revision: Omit<RevisionClass, 'id'>) => void
  addEvaluation: (evaluation: Omit<TestEvaluation, 'id'>) => void
  addNews: (item: Omit<NewsItem, 'id'>) => void
  updateNews: (id: number, patch: Partial<Omit<NewsItem, 'id'>>) => void
  removeNews: (id: number) => void
  addNotification: (item: Omit<NotificationItem, 'id'>) => void
  updateNotification: (id: number, patch: Partial<Omit<NotificationItem, 'id'>>) => void
  deleteNotification: (id: number) => void
  addChatGroup: (group: ChatGroup) => void
  updateChatGroup: (id: string, patch: Partial<Omit<ChatGroup, 'id'>>) => void
  deleteChatGroup: (id: string) => void
  addChatMessage: (message: Omit<ChatMessage, 'id'>) => void
  addTimetableSlot: (slot: Omit<TimetableSlot, 'id'>, teacherEmail: string) => Promise<TimetableSlot>
  updateTimetableSlot: (id: number, slot: Partial<Omit<TimetableSlot, 'id'>>, teacherEmail?: string) => Promise<TimetableSlot>
  deleteTimetableSlot: (id: number) => Promise<void>
  refreshData: () => void
}

export const DataContext = createContext<DataContextValue | undefined>(undefined)

const PERIOD_TIME_BOUNDS: Record<number, { start: string; end: string }> = {
  1: { start: '07:30:00', end: '08:15:00' },
  2: { start: '08:25:00', end: '09:10:00' },
  3: { start: '09:20:00', end: '10:05:00' },
  4: { start: '10:15:00', end: '11:00:00' },
  5: { start: '11:10:00', end: '11:55:00' },
  6: { start: '13:00:00', end: '13:45:00' },
  7: { start: '13:50:00', end: '14:35:00' },
  8: { start: '14:40:00', end: '15:25:00' },
  9: { start: '15:30:00', end: '16:15:00' },
  10: { start: '16:20:00', end: '17:05:00' },
}

const LOCAL_DAY_TO_NUM_MAP: Record<DayOfWeek, number> = {
  Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6
}

export function DataProvider({ children }: { children: ReactNode }) {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const [users, setUsers] = useState<User[]>([])
  const [classes, setClasses] = useState<SchoolClass[]>([])
  const [schoolYears, setSchoolYears] = useState<ApiSchoolYear[]>([])
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [semesters, setSemesters] = useState<Semester[]>([])
  const [exams, setExams] = useState<Exam[]>([])
  const [scores, setScores] = useState<ScoreDetail[]>([])
  const [progress, setProgress] = useState<ProgressDetail[]>([])
  const [attendance, setAttendance] = useState<AttendanceRecord[]>([])
  const [timetable, setTimetable] = useState<TimetableSlot[]>([])
  const [resources, setResources] = useState<Resource[]>([])
  const [revisionClasses, setRevisionClasses] = useState<RevisionClass[]>([])
  const [evaluations, setEvaluations] = useState<TestEvaluation[]>([])
  const [news, setNews] = useState<NewsItem[]>([])
  const [notifications, setNotifications] = useState<NotificationItem[]>([])
  const [chatGroups, setChatGroups] = useState<ChatGroup[]>([])
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([])
  const [helplines, setHelplines] = useState<Helpline[]>([])

  // Backend ID lookup maps — keyed by the frontend primary key so mutations can
  // call the correct REST endpoint without changing the frontend type shapes.
  const userIdByEmail           = useRef(new Map<string, string>())  // email → userId (UUID)
  const classBackendIdByFrontId = useRef(new Map<string, number>())  // classId string → classId int
  const emailByStudentId        = useRef(new Map<string, string>())  // studentId UUID → email
  const studentIdByEmail        = useRef(new Map<string, string>())  // email → studentId UUID
  const teacherIdByEmail        = useRef(new Map<string, string>())  // email → teacherId UUID

  const [refreshTrigger, setRefreshTrigger] = useState(0)
  const refreshData = useCallback(() => {
    setRefreshTrigger(prev => prev + 1)
  }, [])

  useEffect(() => {
    let cancelled = false

    async function bootstrap() {
      // Seed static reference data immediately (no network needed)
      setSubjects(SEED_SUBJECTS)
      setSemesters(SEED_SEMESTERS)

      try {
        const [apiUsers, apiStudents, apiTeachers, apiClasses, apiAssessments,
               apiTimetable, apiResources, apiNewsPosts, apiNotifs, apiChatGroups, apiContacts,
               apiParentLinks, apiParents, apiEnrollments, apiLessons, apiSchoolYears, apiSemesters] =
          await Promise.all([
            getUsers(),
            getStudents(),
            getTeachers(),
            getClasses(),
            getAssessments(),
            getTimetable().catch(() => []),
            getResources().catch(() => []),
            getAllNews().catch(() => []),
            getNotifications().catch(() => []),
            getChatGroups().catch(() => []),
            getContacts().catch(() => []),
            getParentLinks().catch(() => []),
            getParents().catch(() => []),
            getClassEnrollments().catch(() => []),
            getAllLessons().catch(() => []),
            getSchoolYears().catch(() => []),
            getSemesters().catch(() => []),
          ])

        if (cancelled) return

        // Update YEAR_MAP dynamically with fetched school years
        apiSchoolYears.forEach(y => {
          if (y.schoolYearId && y.name) {
            YEAR_MAP[y.schoolYearId] = y.name
          }
        })
        setSchoolYears(apiSchoolYears)
 
        // Update SEMESTER_ID_MAP and map semesters dynamically from DB
        const mappedSemesters: Semester[] = []
        apiSemesters.forEach(s => {
          if (s.semesterId && s.schoolYearId) {
            const yearName = YEAR_MAP[s.schoolYearId] ?? '2025-2026'
            const startYear = yearName.split('-')[0]
            const semNum = s.name.includes('2') ? '2' : '1'
            const frontendSemId = `S${semNum}-${startYear}`
            SEMESTER_ID_MAP[s.semesterId] = frontendSemId
 
            mappedSemesters.push({
              id: frontendSemId,
              name: s.name,
              year: yearName,
              startDate: s.startDate,
              endDate: s.endDate,
            })
          }
        })
        if (mappedSemesters.length > 0) {
          setSemesters(mappedSemesters)
        }

        // Build backend ID maps for use in mutations
        userIdByEmail.current.clear()
        apiUsers.forEach(u => {
          // Students may have email: null — use same formula as mapApiUsersToFrontend
          const email = u.email ?? `${u.username ?? u.userId}@estudiez.edu.vn`
          if (email && u.userId) userIdByEmail.current.set(email, u.userId.toLowerCase())
        })

        classBackendIdByFrontId.current.clear()
        apiClasses.forEach(c => {
          if (c.classId != null) classBackendIdByFrontId.current.set(String(c.classId), c.classId)
        })

        studentIdByEmail.current.clear()
        teacherIdByEmail.current.clear()

        // studentId UUID → frontend email (for mapping marks → ScoreDetail)
        const studentUserIdToEmail = new Map<string, string>()
        apiStudents.forEach(s => {
          const user = apiUsers.find(u => u.userId?.toLowerCase() === s.userId?.toLowerCase())
          const email = user ? (user.email ?? `${user.username ?? user.userId}@estudiez.edu.vn`) : ''
          if (email && s.studentId) {
            const studentIdLower = s.studentId.toLowerCase()
            studentUserIdToEmail.set(studentIdLower, email)
            emailByStudentId.current.set(studentIdLower, email)
            studentIdByEmail.current.set(email, studentIdLower)
          }
        })

        // Lookup maps for mappers that need user name / email by userId
        const nameByUserId = new Map<string, string>(
          apiUsers.map(u => [u.userId!.toLowerCase(), u.fullName ?? u.username ?? '']),
        )
        const emailByUserId = new Map<string, string>()
        apiUsers.forEach(u => {
          const email = u.email ?? `${u.username ?? u.userId}@estudiez.edu.vn`
          if (u.userId) emailByUserId.set(u.userId.toLowerCase(), email)
        })
        // teacherId (Teacher PK) → email and fullName lookups
        const nameByTeacherId = new Map<string, string>()
        const emailByTeacherId = new Map<string, string>()
        apiTeachers.forEach(t => {
          const user = apiUsers.find(u => u.userId?.toLowerCase() === t.userId?.toLowerCase())
          const email = user ? (user.email ?? `${user.username ?? user.userId}@estudiez.edu.vn`) : ''
          if (email && t.teacherId) {
            teacherIdByEmail.current.set(email, t.teacherId.toLowerCase())
            emailByTeacherId.set(t.teacherId.toLowerCase(), email)
          }
          if (t.teacherId && t.userId) {
            nameByTeacherId.set(t.teacherId.toLowerCase(), nameByUserId.get(t.userId.toLowerCase()) ?? '')
          }
        })

        // Build parent → child email mapping from parent-student links
        // parentId (Parent PK) → userId, then userId → email
        const userIdByParentId = new Map<string, string>()
        apiParents.forEach(p => {
          if (p.parentId && p.userId) userIdByParentId.set(p.parentId.toLowerCase(), p.userId.toLowerCase())
        })
        // studentId (Student PK) → email (from earlier studentUserIdToEmail + apiStudents)
        const emailByStudentPk = new Map<string, string>()
        apiStudents.forEach(s => {
          if (s.studentId) {
            const email = studentUserIdToEmail.get(s.studentId.toLowerCase())
            if (email) emailByStudentPk.set(s.studentId.toLowerCase(), email)
          }
        })
        // parentUserId → childEmail (first linked child)
        const childEmailByParentUserId = new Map<string, string>()
        apiParentLinks.forEach(link => {
          const parentUserId = userIdByParentId.get(link.id.parentId.toLowerCase())
          const childEmail = emailByStudentPk.get(link.id.studentId.toLowerCase())
          if (parentUserId && childEmail && !childEmailByParentUserId.has(parentUserId)) {
            childEmailByParentUserId.set(parentUserId, childEmail)
          }
        })

        // Build studentId → classId from active enrollments
        const classIdByStudentPk = new Map<string, number>()
        apiEnrollments.forEach(e => {
          if (e.studentId && e.classId && e.status === 'ACTIVE') {
            classIdByStudentPk.set(e.studentId.toLowerCase(), e.classId)
          }
        })

        // Build userId → studentId (Student PK) for mapping classId
        const studentPkByUserId = new Map<string, string>()
        apiStudents.forEach(s => {
          if (s.userId && s.studentId) studentPkByUserId.set(s.userId.toLowerCase(), s.studentId.toLowerCase())
        })

        // Map users and enrich parent users with childEmail, students with classId
        const mappedUsers = mapApiUsersToFrontend(apiUsers, apiStudents, apiTeachers).map(u => {
          if (u.role === 'parent' && u.userId) {
            const childEmail = childEmailByParentUserId.get(u.userId.toLowerCase())
            if (childEmail) return { ...u, childEmail }
          }
          if (u.role === 'student' && u.userId) {
            const studentPk = studentPkByUserId.get(u.userId.toLowerCase())
            if (studentPk) {
              const classId = classIdByStudentPk.get(studentPk)
              if (classId != null) return { ...u, classId: String(classId) }
            }
          }
          return u
        })
        setUsers(mappedUsers)
        setClasses(apiClasses.map(c => mapApiClass(c, emailByTeacherId)))
        setExams(apiAssessments.map(mapApiAssessmentToExam))

        if (apiTimetable.length > 0)
          setTimetable(apiTimetable.map(s => mapApiTimetableSlot(s, nameByTeacherId)))

        if (apiResources.length > 0)
          setResources(apiResources.map(r => mapApiStudyResource(r, nameByUserId)))

        if (apiNewsPosts.length > 0)
          setNews(apiNewsPosts.map(n => mapApiNewsPost(n, nameByUserId)))

        if (apiNotifs.length > 0)
          setNotifications(apiNotifs.map(n => mapApiNotification(n, nameByUserId)))

        if (apiChatGroups.length > 0) {
          const groups = apiChatGroups.map(mapApiChatGroup)
          setChatGroups(groups)
          // Load messages for all groups in parallel
          const msgBatches = await Promise.all(
            (apiChatGroups as ApiChatGroup[]).map(g =>
              getChatMessages(g.chatGroupId!).catch(() => [] as ApiChatMessage[]),
            ),
          )
          const allMessages = (apiChatGroups as ApiChatGroup[]).flatMap((_g, i) =>
            msgBatches[i].map(m => mapApiChatMessage(m, nameByUserId, emailByUserId)),
          )
          if (!cancelled && allMessages.length > 0) setChatMessages(allMessages)
        }

        if (apiContacts.length > 0)
          setHelplines(apiContacts.map(mapApiContact))

        // Fetch marks for every assessment in parallel
        if (apiAssessments.length > 0 && studentUserIdToEmail.size > 0) {
          const markBatches = await Promise.all(
            apiAssessments.map(a =>
              getMarksByAssessment(a.assessmentId!).catch(() => [] as ApiMark[]),
            ),
          )
          const apiScores = (apiAssessments as ApiAssessment[]).flatMap((a, i) =>
            markBatches[i].map(m => mapApiMarkToScore(m, a, studentUserIdToEmail)),
          )
          if (!cancelled && apiScores.length > 0) setScores(apiScores)

          // Load evaluations from the saved marks' remarks
          const derivedEvaluations: TestEvaluation[] = []
          ;(apiAssessments as ApiAssessment[]).forEach((a, i) => {
            markBatches[i].forEach(m => {
              if (m.remark && m.remark.startsWith('{')) {
                try {
                  const evalData = JSON.parse(m.remark)
                  const studentEmail = m.studentId ? studentUserIdToEmail.get(m.studentId) : undefined
                  if (studentEmail) {
                    derivedEvaluations.push({
                      id: m.studentMarkId ?? 0,
                      studentEmail,
                      subject: SUBJECT_ID_MAP[a.subjectId ?? 0] ?? String(a.subjectId),
                      testId: String(m.assessmentId ?? ''),
                      score: m.score ?? 0,
                      ...evalData
                    })
                  }
                } catch (e) {
                  console.warn('Failed to parse evaluation JSON:', e)
                }
              }
            })
          })
          if (!cancelled && derivedEvaluations.length > 0) setEvaluations(derivedEvaluations)

          // Derive student classId + grade from which assessment they have marks in
          if (!cancelled) {
            const classByBackendId = new Map(
              apiClasses.map(c => [c.classId!, c]),
            )
            const emailToClassId = new Map<string, string>()
            const emailToGrade = new Map<string, Grade>()
            ;(apiAssessments as ApiAssessment[]).forEach((a, i) => {
              if (a.classId == null) return
              const cls = classByBackendId.get(a.classId)
              const grade = cls ? (GRADE_MAP[cls.gradeId ?? 1] ?? 10) : 10
              markBatches[i].forEach(m => {
                const email = m.studentId ? studentUserIdToEmail.get(m.studentId) : undefined
                if (email && !emailToClassId.has(email)) {
                  emailToClassId.set(email, String(a.classId))
                  emailToGrade.set(email, grade)
                }
              })
            })
            if (emailToClassId.size > 0) {
              setUsers(prev =>
                prev.map(u => {
                  if (u.role !== 'student') return u
                  const classId = emailToClassId.get(u.email)
                  const grade = emailToGrade.get(u.email)
                  if (!classId && grade == null) return u
                  return { ...u, classId: u.classId || classId, grade: u.grade || grade }
                }),
              )
            }
          }
        }

        // Fetch attendance records from lesson sessions
        if (apiLessons.length > 0 && emailByStudentId.current.size > 0) {
          // Build lesson session map for quick lookup
          const lessonById = new Map<number, ApiLessonSession>(
            (apiLessons as ApiLessonSession[]).map(l => [l.lessonSessionId!, l]),
          )

          // Fetch all attendance records in a single batch query
          const allAttendance = await getAllAttendance().catch(() => [] as ApiAttendanceRecord[])

          // Map to frontend AttendanceRecord
          const mappedAttendance: AttendanceRecord[] = allAttendance.flatMap(a => {
              const lesson = lessonById.get(a.lessonSessionId ?? 0)
              if (!lesson || !a.studentId) return []
              const studentEmail = emailByStudentId.current.get(a.studentId) ?? ''
              if (!studentEmail) return []
              // Normalize date to YYYY-MM-DD format (strip time portion if present)
              const rawDate = lesson.sessionDate ?? ''
              const normalizedDate = rawDate.includes('T') ? rawDate.split('T')[0] : rawDate.slice(0, 10)
              return [{
                id: a.attendanceRecordId ?? 0,
                studentEmail,
                classId: String(lesson.classId ?? ''),
                subject: SUBJECT_ID_MAP[lesson.subjectId ?? 0] ?? String(lesson.subjectId ?? ''),
                date: normalizedDate,
                period: lesson.periodNo ?? 0,
                status: (a.status ?? 'present').toLowerCase() as AttendanceStatus,
                teacher: nameByTeacherId.get(lesson.teacherId ?? '') ?? lesson.teacherId ?? '',
                note: a.note ?? '',
              }]
            })

          if (!cancelled && mappedAttendance.length > 0) setAttendance(mappedAttendance)
        }
      } catch (err) {
        if (!cancelled) {
          console.warn('[DataContext] Backend unavailable:', err)
          setError(err instanceof Error ? err.message : 'Failed to load data')
        }
      } finally {
        if (!cancelled) setLoading(false)
      }
    }

    bootstrap()
    return () => {
      cancelled = true
    }
  }, [refreshTrigger])

  // Poll chat messages from backend every 4 seconds to sync messages automatically on Web client
  useEffect(() => {
    let cancelled = false
    let timerId: any = null

    async function poll() {
      if (chatGroups.length === 0) return
      try {
        const msgBatches = await Promise.all(
          chatGroups.map(g =>
            getChatMessages(Number(g.id)).catch(() => [] as ApiChatMessage[]),
          ),
        )
        if (cancelled) return

        // Map names and emails
        const nameByUserId = new Map<string, string>()
        const emailByUserId = new Map<string, string>()
        users.forEach(u => {
          if (u.userId) {
            nameByUserId.set(u.userId.toLowerCase(), u.fullName)
            emailByUserId.set(u.userId.toLowerCase(), u.email)
          }
        })

        const allMessages = chatGroups.flatMap((_, i) =>
          msgBatches[i].map(m => mapApiChatMessage(m, nameByUserId, emailByUserId)),
        )

        setChatMessages(prev => {
          if (prev.length !== allMessages.length) return allMessages
          for (let idx = 0; idx < prev.length; idx++) {
            if (prev[idx].id !== allMessages[idx].id || prev[idx].body !== allMessages[idx].body) {
              return allMessages
            }
          }
          return prev
        })
      } catch (e) {
        console.warn('Failed to poll chat messages:', e)
      }
    }

    timerId = setInterval(poll, 4000)

    return () => {
      cancelled = true
      if (timerId) clearInterval(timerId)
    }
  }, [chatGroups, users])

  const addUser = useCallback((user: User) => setUsers((prev) => [...prev, user]), [])
  const updateUser = useCallback(
    (email: string, patch: Partial<Omit<User, 'email' | 'role'>>) => {
      const normalized = email.trim().toLowerCase()
      let updated: User | null = null
      setUsers((prev) =>
        prev.map((user) => {
          if (user.email !== normalized) return user
          updated = { ...user, ...patch }
          return updated
        }),
      )
      return updated
    },
    [],
  )
  const deleteUser = useCallback((email: string) => {
    const normalized = email.trim().toLowerCase()
    setUsers((prev) => prev.filter((user) => user.email !== normalized))
    const userId = userIdByEmail.current.get(normalized)
    if (userId) deleteApiUser(userId).catch(console.warn)
  }, [])
  const addClass = useCallback(
    (schoolClass: SchoolClass) => setClasses((prev) => [...prev, schoolClass]),
    [],
  )
  const updateClass = useCallback(
    (id: string, patch: Partial<Omit<SchoolClass, 'id'>>) =>
      setClasses((prev) => prev.map((c) => (c.id === id ? { ...c, ...patch } : c))),
    [],
  )
  const deleteClass = useCallback((id: string) => {
    setClasses((prev) => prev.filter((c) => c.id !== id))
    const backendId = classBackendIdByFrontId.current.get(id)
    if (backendId !== undefined) deleteApiClass(backendId).catch(console.warn)
  }, [])
  const addSemester = useCallback(
    (semester: Semester) => setSemesters((prev) => [...prev, semester]),
    [],
  )
  const updateSemester = useCallback(
    (id: string, patch: Partial<Omit<Semester, 'id'>>) =>
      setSemesters((prev) => prev.map((s) => (s.id === id ? { ...s, ...patch } : s))),
    [],
  )
  const deleteSemester = useCallback((id: string) => {
    setSemesters((prev) => prev.filter((s) => s.id !== id))
    setExams((prev) => prev.filter((e) => e.semesterId !== id))
  }, [])
  const addExam = useCallback(
    async (exam: Omit<Exam, 'id'>, teacherEmail: string) => {
      const subjectId = Number(Object.entries(SUBJECT_ID_MAP).find(([_, val]) => val === exam.subject)?.[0] ?? 0)
      const semesterId = Number(Object.entries(SEMESTER_ID_MAP).find(([_, val]) => val === exam.semesterId)?.[0] ?? 1)
      const tId = teacherIdByEmail.current.get(teacherEmail.toLowerCase()) || '00000000-0000-0000-0000-000000000000'
      try {
        const created = await createApiAssessment({
          classId: Number(exam.classId),
          subjectId,
          semesterId,
          assessmentTypeId: 1, // default type
          title: exam.name,
          assessmentDate: exam.date,
          maxScore: 10,
          weight: exam.weight ?? 0.1,
          status: exam.completed ? 'COMPLETED' : 'SCHEDULED',
          teacherId: tId as any,
        })
        setExams((prev) => [...prev, mapApiAssessmentToExam(created)])
      } catch (err) {
        console.error('Failed to create assessment:', err)
      }
    },
    [],
  )
  const updateExam = useCallback(
    (id: number, patch: Partial<Omit<Exam, 'id'>>) =>
      setExams((prev) => prev.map((e) => (e.id === id ? { ...e, ...patch } : e))),
    [],
  )
  const deleteExam = useCallback(
    (id: number) => setExams((prev) => prev.filter((e) => e.id !== id)),
    [],
  )
  const addScore = useCallback(
    (score: Omit<ScoreDetail, 'id'>) =>
      setScores((prev) => [...prev, { ...score, id: nextId(prev) }]),
    [],
  )
  const addProgress = useCallback(
    (entry: Omit<ProgressDetail, 'id'>) =>
      setProgress((prev) => [...prev, { ...entry, id: nextId(prev) }]),
    [],
  )
  const addAttendance = useCallback(
    (record: Omit<AttendanceRecord, 'id'>) =>
      setAttendance((prev) => [...prev, { ...record, id: nextId(prev) }]),
    [],
  )
  const saveAttendanceBatch = useCallback(
    async (
      classId: string,
      subject: string,
      date: string,
      period: number,
      teacherEmail: string,
      records: { studentEmail: string; status: AttendanceStatus; note: string }[]
    ) => {
      const numericClassId = Number(classId)
      const subjectId = SEED_SUBJECTS.findIndex((s) => s.name === subject) + 1
      const teacherUuid = teacherIdByEmail.current.get(teacherEmail)
      const teacherUserUuid = userIdByEmail.current.get(teacherEmail)

      if (!teacherUuid || !teacherUserUuid) {
        throw new Error('Teacher not found.')
      }

      // 1. Find or create lesson session
      const lessons = await getLessonsByClass(numericClassId).catch(() => [] as ApiLessonSession[])
      let session = lessons.find(
        (l) =>
          l.sessionDate === date &&
          l.periodNo === period &&
          l.subjectId === subjectId &&
          l.teacherId === teacherUuid,
      )

      if (!session) {
        session = await createLessonSession({
          classId: numericClassId,
          subjectId,
          teacherId: teacherUuid,
          sessionDate: date,
          periodNo: period,
          status: 'COMPLETED',
        })
      }

      if (!session.lessonSessionId) {
        throw new Error('Failed to retrieve or create lesson session.')
      }

      const lessonSessionId = session.lessonSessionId

      // 2. Post attendance records in parallel
      const savedApiRecords = await Promise.all(
        records.map(async (r) => {
          const studentUuid = studentIdByEmail.current.get(r.studentEmail)
          if (!studentUuid) {
            throw new Error(`Student ${r.studentEmail} not found.`)
          }
          const apiRec: ApiAttendanceRecord = {
            studentId: studentUuid,
            status: r.status.toUpperCase(),
            note: r.note,
            recordedBy: teacherUserUuid,
          }
          const saved = await recordAttendance(lessonSessionId, apiRec)
          return { ...saved, studentEmail: r.studentEmail }
        }),
      )

      // 3. Map to frontend format
      const newRecords: AttendanceRecord[] = savedApiRecords.map((a) => ({
        id: a.attendanceRecordId ?? 0,
        studentEmail: a.studentEmail,
        classId,
        subject,
        date,
        period,
        status: (a.status ?? 'present').toLowerCase() as AttendanceStatus,
        teacher: users.find((u) => u.email === teacherEmail)?.fullName ?? 'Teacher',
        note: a.note ?? '',
      }))

      // 4. Update state (replace existing to avoid duplicates in state)
      setAttendance((prev) => {
        const filtered = prev.filter(
          (item) =>
            !(
              item.classId === classId &&
              item.subject === subject &&
              item.date === date &&
              item.period === period
            ),
        )
        return [...filtered, ...newRecords]
      })
    },
    [users],
  )
  const saveMarksAndEvaluationsBatch = useCallback(
    async (
      examId: number,
      classId: string,
      subject: string,
      teacherEmail: string,
      records: {
        studentEmail: string
        score: number
        evaluation?: {
          performanceLevel: 'excellent' | 'good' | 'average' | 'below-average' | 'poor'
          topicsMastered?: string
          topicsToImprove?: string
          studyHabits: 'consistent' | 'irregular' | 'needs-work'
          teacherNotes?: string
          strengths: string
          weaknesses: string
          suggestedPath: string
          teacher: string
        }
      }[]
    ) => {
      const teacherUuid = teacherIdByEmail.current.get(teacherEmail)
      if (!teacherUuid) {
        throw new Error('Teacher not found.')
      }

      const exam = exams.find((e) => e.id === examId)
      const examName = exam?.name ?? 'Exam'
      const examDate = exam?.date ?? new Date().toISOString().split('T')[0]

      // Call API to save marks
      const results = await Promise.all(
        records.map(async (rec) => {
          const studentUuid = studentIdByEmail.current.get(rec.studentEmail)
          if (!studentUuid) {
            console.warn(`Student UUID not found for email: ${rec.studentEmail}`)
            return null
          }

          const apiMark: ApiMark = {
            assessmentId: examId,
            studentId: studentUuid,
            score: rec.score,
            remark: rec.evaluation ? JSON.stringify(rec.evaluation) : undefined,
            gradedBy: teacherUuid,
          }

          const saved = await saveMarkApi(examId, apiMark)
          return { rec, saved }
        })
      )

      // Update local React state so it shows up immediately
      setScores((prev) => {
        let next = [...prev]
        results.forEach((res) => {
          if (!res) return
          const { rec, saved } = res
          // Remove if already exists in state
          next = next.filter(
            (s) => !(s.studentEmail === rec.studentEmail && s.testId === String(examId))
          )
          next.push({
            id: saved.studentMarkId ?? nextId(prev),
            studentEmail: rec.studentEmail,
            classId,
            subject,
            testId: String(examId),
            description: examName,
            date: examDate,
            scoreReceived: rec.score,
          })
        })
        return next
      })

      setEvaluations((prev) => {
        let next = [...prev]
        results.forEach((res) => {
          if (!res) return
          const { rec, saved } = res
          if (!rec.evaluation) return
          // Remove if already exists in state
          next = next.filter(
            (e) => !(e.studentEmail === rec.studentEmail && e.testId === String(examId))
          )
          next.push({
            id: saved.studentMarkId ?? nextId(prev),
            studentEmail: rec.studentEmail,
            subject,
            testId: String(examId),
            score: rec.score,
            ...rec.evaluation,
            strengths: rec.evaluation.strengths ?? '',
            weaknesses: rec.evaluation.weaknesses ?? '',
          })
        })
        return next
      })
    },
    [exams],
  )
  const addResource = useCallback(
    (resource: Omit<Resource, 'id'>) =>
      setResources((prev) => [...prev, { ...resource, id: nextId(prev) }]),
    [],
  )
  const addRevisionClass = useCallback(
    (revision: Omit<RevisionClass, 'id'>) =>
      setRevisionClasses((prev) => [...prev, { ...revision, id: nextId(prev) }]),
    [],
  )
  const addEvaluation = useCallback(
    (evaluation: Omit<TestEvaluation, 'id'>) =>
      setEvaluations((prev) => [...prev, { ...evaluation, id: nextId(prev) }]),
    [],
  )
  const addNews = useCallback(
    (item: Omit<NewsItem, 'id'>) => setNews((prev) => [{ ...item, id: nextId(prev) }, ...prev]),
    [],
  )
  const updateNews = useCallback(
    (id: number, patch: Partial<Omit<NewsItem, 'id'>>) =>
      setNews((prev) => prev.map((n) => (n.id === id ? { ...n, ...patch } : n))),
    [],
  )
  const removeNews = useCallback(
    (id: number) => setNews((prev) => prev.filter((n) => n.id !== id)),
    [],
  )
  const addNotification = useCallback(
    (item: Omit<NotificationItem, 'id'>) =>
      setNotifications((prev) => [{ ...item, id: nextId(prev) }, ...prev]),
    [],
  )
  const updateNotification = useCallback(
    (id: number, patch: Partial<Omit<NotificationItem, 'id'>>) =>
      setNotifications((prev) => prev.map((n) => (n.id === id ? { ...n, ...patch } : n))),
    [],
  )
  const deleteNotification = useCallback(
    (id: number) => {
      setNotifications((prev) => prev.filter((n) => n.id !== id))
      deleteApiNotificationApi(id).catch(console.warn)
    },
    [],
  )
  const addChatGroup = useCallback(
    (group: ChatGroup) => setChatGroups((prev) => [...prev, group]),
    [],
  )
  const updateChatGroup = useCallback(
    (id: string, patch: Partial<Omit<ChatGroup, 'id'>>) =>
      setChatGroups((prev) => prev.map((g) => (g.id === id ? { ...g, ...patch } : g))),
    [],
  )
  const deleteChatGroup = useCallback((id: string) => {
    setChatGroups((prev) => prev.filter((g) => g.id !== id))
    setChatMessages((prev) => prev.filter((m) => m.groupId !== id))
  }, [])
  const addChatMessage = useCallback(
    (message: Omit<ChatMessage, 'id'>) => {
      setChatMessages((prev) => [...prev, { ...message, id: nextId(prev) }])
      // Find sender's userId from their email
      const sender = users.find((u) => u.email === message.senderEmail)
      const senderUserId = sender?.userId
      if (senderUserId) {
        sendChatMessage({
          chatGroupId: Number(message.groupId),
          senderUserId,
          messageText: message.body,
        }).catch(console.warn)
      }
    },
    [users],
  )

  const addTimetableSlot = useCallback(
    async (slot: Omit<TimetableSlot, 'id'>, teacherEmail: string) => {
      const classIdInt = classBackendIdByFrontId.current.get(slot.classId)
      if (!classIdInt) throw new Error('Invalid class ID')

      const subjectId = Number(Object.entries(SUBJECT_ID_MAP).find(([_, name]) => name === slot.subject)?.[0] ?? 1)
      const semId = Number(Object.entries(SEMESTER_ID_MAP).find(([_, id]) => id === slot.semesterId)?.[0] ?? 1)
      
      const teacherUUID = teacherIdByEmail.current.get(teacherEmail.toLowerCase())
      if (!teacherUUID) throw new Error('Invalid teacher email')

      const dayOfWeekNum = LOCAL_DAY_TO_NUM_MAP[slot.day] ?? 1
      const timeBounds = PERIOD_TIME_BOUNDS[slot.period] || { start: '00:00:00', end: '00:00:00' }

      const sem = semesters.find(s => s.id === slot.semesterId)
      const effFrom = sem ? sem.startDate : '2026-06-01'
      const effTo = sem ? sem.endDate : '2026-11-30'

      const apiSlot = {
        classId: classIdInt,
        subjectId,
        teacherId: teacherUUID,
        semesterId: semId,
        dayOfWeek: dayOfWeekNum,
        periodNo: slot.period,
        startTime: timeBounds.start,
        endTime: timeBounds.end,
        room: slot.room,
        effectiveFrom: effFrom,
        effectiveTo: effTo
      }

      const created = await createApiTimetable(apiSlot)
      
      const mapped = mapApiTimetableSlot(
        created,
        new Map(users.map(u => [u.userId?.toLowerCase() ?? '', u.fullName]))
      )
      
      setTimetable(prev => [...prev, mapped])
      return mapped
    },
    [users, semesters]
  )

  const updateTimetableSlot = useCallback(
    async (id: number, patch: Partial<Omit<TimetableSlot, 'id'>>, teacherEmail?: string) => {
      const existing = timetable.find(s => s.id === id)
      if (!existing) throw new Error('Slot not found')

      const merged = { ...existing, ...patch }
      
      const classIdInt = classBackendIdByFrontId.current.get(merged.classId)
      if (!classIdInt) throw new Error('Invalid class ID')

      const subjectId = Number(Object.entries(SUBJECT_ID_MAP).find(([_, name]) => name === merged.subject)?.[0] ?? 1)
      const semId = Number(Object.entries(SEMESTER_ID_MAP).find(([_, id]) => id === merged.semesterId)?.[0] ?? 1)
      
      let teacherUUID: string | undefined
      if (teacherEmail) {
        teacherUUID = teacherIdByEmail.current.get(teacherEmail.toLowerCase())
      } else {
        const teacherUser = users.find(u => u.role === 'teacher' && u.fullName === merged.teacher)
        if (teacherUser) {
          teacherUUID = userIdByEmail.current.get(teacherUser.email.toLowerCase())
        }
      }
      
      const dayOfWeekNum = LOCAL_DAY_TO_NUM_MAP[merged.day] ?? 1
      const timeBounds = PERIOD_TIME_BOUNDS[merged.period] || { start: '00:00:00', end: '00:00:00' }

      const sem = semesters.find(s => s.id === merged.semesterId)
      const effFrom = sem ? sem.startDate : '2026-06-01'
      const effTo = sem ? sem.endDate : '2026-11-30'

      const apiSlot = {
        timetableSlotId: id,
        classId: classIdInt,
        subjectId,
        teacherId: teacherUUID,
        semesterId: semId,
        dayOfWeek: dayOfWeekNum,
        periodNo: merged.period,
        startTime: timeBounds.start,
        endTime: timeBounds.end,
        room: merged.room,
        effectiveFrom: effFrom,
        effectiveTo: effTo
      }

      const updated = await updateApiTimetable(id, apiSlot)
      
      const mapped = mapApiTimetableSlot(
        updated,
        new Map(users.map(u => [u.userId?.toLowerCase() ?? '', u.fullName]))
      )
      
      setTimetable(prev => prev.map(s => s.id === id ? mapped : s))
      return mapped
    },
    [timetable, users, semesters]
  )

  const deleteTimetableSlot = useCallback(
    async (id: number) => {
      await deleteApiTimetable(id)
      setTimetable(prev => prev.filter(s => s.id !== id))
    },
    []
  )

  const value = useMemo<DataContextValue>(
    () => ({
      loading,
      error,
      users,
      classes,
      schoolYears,
      subjects,
      semesters,
      exams,
      scores,
      progress,
      attendance,
      timetable,
      resources,
      revisionClasses,
      evaluations,
      news,
      notifications,
      chatGroups,
      chatMessages,
      helplines,
      addUser,
      updateUser,
      deleteUser,
      addClass,
      updateClass,
      deleteClass,
      addSemester,
      updateSemester,
      deleteSemester,
      addExam,
      updateExam,
      deleteExam,
      addScore,
      addProgress,
      addAttendance,
      saveAttendanceBatch,
      saveMarksAndEvaluationsBatch,
      addResource,
      addRevisionClass,
      addEvaluation,
      addNews,
      updateNews,
      removeNews,
      addNotification,
      updateNotification,
      deleteNotification,
      addChatGroup,
      updateChatGroup,
      deleteChatGroup,
      addChatMessage,
      addTimetableSlot,
      updateTimetableSlot,
      deleteTimetableSlot,
      refreshData,
    }),
    [
      loading,
      error,
      users,
      classes,
      schoolYears,
      subjects,
      semesters,
      exams,
      scores,
      progress,
      attendance,
      timetable,
      resources,
      revisionClasses,
      evaluations,
      news,
      notifications,
      chatGroups,
      chatMessages,
      helplines,
      addUser,
      updateUser,
      deleteUser,
      addClass,
      updateClass,
      deleteClass,
      addSemester,
      updateSemester,
      deleteSemester,
      addExam,
      updateExam,
      deleteExam,
      addScore,
      addProgress,
      addAttendance,
      saveAttendanceBatch,
      saveMarksAndEvaluationsBatch,
      addResource,
      addRevisionClass,
      addEvaluation,
      addNews,
      updateNews,
      removeNews,
      addNotification,
      updateNotification,
      deleteNotification,
      addChatGroup,
      updateChatGroup,
      deleteChatGroup,
      addChatMessage,
      addTimetableSlot,
      updateTimetableSlot,
      deleteTimetableSlot,
      refreshData,
    ],
  )

  return <DataContext.Provider value={value}>{children}</DataContext.Provider>
}

function nextId(items: { id: number }[]): number {
  return items.reduce((max, item) => (item.id > max ? item.id : max), 0) + 1
}
