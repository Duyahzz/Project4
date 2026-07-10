import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { Card } from '../../components/Card'
import { ChatPanel } from '../../components/ChatPanel'
import { FormField } from '../../components/FormField'
import { Tabs } from '../../components/Tabs'
import { TimetableGrid } from '../../components/TimetableGrid'
import { useAuth } from '../../hooks/useAuth'
import { useData } from '../../hooks/useData'
import { useToast } from '../../hooks/useToast'
import { notificationDetailPath } from '../notificationDetailPath'
import { AttendanceTab, MarksTab } from './StudentDashboard'

export function ParentDashboard() {
  const { currentUser, setCurrentUser } = useAuth()
  const { attendance, news, notifications, chatGroups, helplines, users, updateUser, classes, semesters } =
    useData()
  const { push } = useToast()

  const [timetableSemesterId, setTimetableSemesterId] = useState(() => {
    const today = new Date().toISOString().slice(0, 10)
    return semesters.find((s) => today >= s.startDate && today <= s.endDate)?.id 
      ?? semesters[semesters.length - 1]?.id 
      ?? 'S2-2025'
  })

  const child = useMemo(() => {
    if (!currentUser?.childEmail) return null
    return users.find((user) => user.email === currentUser.childEmail) ?? null
  }, [currentUser, users])

  const childEmail = currentUser?.childEmail ?? ''
  const childClassId = child?.classId ?? ''

  const childClassName = useMemo(() => {
    return classes.find(c => c.id === childClassId)?.name ?? childClassId
  }, [classes, childClassId])

  const childAttendance = useMemo(
    () => attendance.filter((item) => item.studentEmail === childEmail),
    [attendance, childEmail],
  )
  const myNotifications = useMemo(
    () =>
      notifications.filter(
        (n) =>
          (n.audience === 'parent' && n.target === currentUser?.email) ||
          (n.audience === 'class' && n.target === childClassId),
      ),
    [notifications, currentUser, childClassId],
  )
  const parentChatGroup = useMemo(
    () => chatGroups.find((g) => g.classId === childClassId && g.type === 'parent-teacher'),
    [chatGroups, childClassId],
  )

  const [contact, setContact] = useState({
    email: currentUser?.email ?? '',
    phone: currentUser?.phone ?? '',
  })
  const [contactError, setContactError] = useState('')

  const saveContact = (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    if (contact.phone && !/^[+\d][\d\s()-]{5,}$/.test(contact.phone)) {
      setContactError('Enter a valid phone number.')
      return
    }
    setContactError('')
    const updated = updateUser(currentUser!.email, { phone: contact.phone.trim() })
    if (updated) {
      setCurrentUser(updated)
      push('success', 'Contact info updated.')
    }
  }

  return (
    <Tabs
      tabs={[
        {
          id: 'contact',
          label: 'My Contact',
          content: (
            <Card
              title="Contact Information"
              description={
                child ? `Linked child: ${child.fullName} (${child.email})` : 'No linked child.'
              }
            >
              <form onSubmit={saveContact} noValidate className="grid sm:grid-cols-2 gap-4">
                <FormField
                  label="Email (login, read-only)"
                  name="parentEmailField"
                  value={contact.email}
                  onChange={() => undefined}
                  disabled
                />
                <FormField
                  label="Phone"
                  name="parentPhone"
                  value={contact.phone}
                  onChange={(e) => setContact((p) => ({ ...p, phone: e.target.value }))}
                  error={contactError || undefined}
                />
                <div className="sm:col-span-2">
                  <button
                    type="submit"
                    className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-4 py-2"
                  >
                    Save Contact Info
                  </button>
                </div>
              </form>
            </Card>
          ),
        },
        {
          id: 'timetable',
          label: 'Timetable',
          content: (
            <Card title="Child's Timetable" description={child ? `Class ${childClassName}` : ''}>
              {childClassId ? (
                <>
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
                  <TimetableGrid classId={childClassId} studentEmail={childEmail} semesterId={timetableSemesterId} />
                </>
              ) : (
                <p className="text-sm text-rose-600">No linked child account.</p>
              )}
            </Card>
          ),
        },
        {
          id: 'marks',
          label: 'Marks',
          content: <MarksTab email={childEmail} />,
        },
        {
          id: 'attendance',
          label: 'Attendance',
          content: <AttendanceTab studentAttendance={childAttendance} classId={childClassId} />,
        },
        {
          id: 'news',
          label: 'School News',
          content: (
            <Card title="School News">
              <ul className="space-y-3">
                {news.map((item) => (
                  <li key={item.id} className="border border-slate-200 rounded-lg px-3 py-2">
                    <div className="flex items-center justify-between gap-2">
                      <p className="font-semibold text-slate-900">{item.title}</p>
                      <span className="text-xs rounded-full bg-slate-100 text-slate-600 px-2 py-0.5">
                        {item.category}
                      </span>
                    </div>
                    <p className="text-sm text-slate-600 mt-1">{item.body}</p>
                    <p className="text-xs text-slate-400 mt-1">
                      {item.date} · {item.author}
                    </p>
                  </li>
                ))}
              </ul>
            </Card>
          ),
        },
        {
          id: 'notifications',
          label: 'Notifications',
          content: (
            <Card title="Notifications about my child">
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
          label: 'Parent Chat',
          content: (
            <Card title="Parent Chat Group" description="Parents & teachers of the class">
              {parentChatGroup ? (
                <ChatPanel groupId={parentChatGroup.id} />
              ) : (
                <p className="text-sm text-slate-500">No parent chat group for this class yet.</p>
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
          label: 'Child Grade Progress',
          content: (
            <div className="space-y-4">
              {!child ? (
                <Card>
                  <p className="text-sm text-slate-500">No linked child account.</p>
                </Card>
              ) : (
                <>
                  <Card title={`${child.fullName}'s Current Grade Status`}>
                    <div className="grid sm:grid-cols-3 gap-4">
                      <div className="border-2 border-indigo-600 rounded-lg p-4 text-center">
                        <p className="text-xs text-slate-500 uppercase tracking-wide mb-1">Current Grade</p>
                        <p className="text-4xl font-bold text-indigo-600">{child.grade ?? '—'}</p>
                      </div>
                      <div className="border border-slate-200 rounded-lg p-4 text-center">
                        <p className="text-xs text-slate-500 uppercase tracking-wide mb-1">Class</p>
                        <p className="text-2xl font-semibold text-slate-900">{childClassName}</p>
                      </div>
                      <div className="border border-slate-200 rounded-lg p-4 text-center">
                        <p className="text-xs text-slate-500 uppercase tracking-wide mb-1">Status</p>
                        <p className="text-2xl font-semibold text-emerald-600">Active</p>
                      </div>
                    </div>
                  </Card>

                  <Card title="Grade Progression Timeline">
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
                          <div className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold text-sm ${ child.grade && child.grade >= 11 ? 'bg-indigo-600 text-white' : 'bg-slate-200 text-slate-400'}`}>
                            11
                          </div>
                          <div className="w-0.5 h-8 bg-slate-200 mt-1"></div>
                        </div>
                        <div>
                          <p className={`font-semibold ${ child.grade && child.grade >= 11 ? 'text-slate-900' : 'text-slate-400'}`}>
                            Grade 11 - Promotion
                          </p>
                          <p className={`text-sm ${ child.grade && child.grade >= 11 ? 'text-slate-600' : 'text-slate-400'}`}>
                            {child.grade && child.grade >= 11 ? 'Completed' : 'Not yet reached'}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-3">
                        <div className={`w-10 h-10 rounded-full flex items-center justify-center font-semibold text-sm ${ child.grade === 12 ? 'bg-amber-600 text-white' : 'bg-slate-200 text-slate-400'}`}>
                          12
                        </div>
                        <div>
                          <p className={`font-semibold ${ child.grade === 12 ? 'text-slate-900' : 'text-slate-400'}`}>
                            Grade 12 - Final Year
                          </p>
                          <p className={`text-sm ${ child.grade === 12 ? 'text-slate-600' : 'text-slate-400'}`}>
                            {child.grade === 12 ? 'Currently in final year' : 'Not yet reached'}
                          </p>
                        </div>
                      </div>
                    </div>
                  </Card>

                  <Card title="Parent Notifications">
                    <ul className="space-y-2 text-sm text-slate-700">
                      <li className="flex items-start gap-3 p-3 bg-blue-50 border border-blue-200 rounded-lg">
                        <span className="text-blue-600 font-bold mt-0.5">ℹ</span>
                        <span>Grade progression updates will appear here. You'll be notified when your child is promoted to the next grade or graduates.</span>
                      </li>
                    </ul>
                  </Card>
                </>
              )}
            </div>
          ),
        },
      ]}
    />
  )
}
