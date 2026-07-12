import { useState, useMemo, useEffect } from 'react'
import { Card } from '../../components/Card'
import { FormField } from '../../components/FormField'
import { useData } from '../../hooks/useData'
import { useToast } from '../../hooks/useToast'
import { batchPromoteStudents, batchAssignGradeAndClass, updateApiClass, getSchoolYears, findOrCreateSchoolYear, createApiClass, getClasses } from '../../services/api'
import type { ApiSchoolYear } from '../../services/api'

const AVAILABLE_ROOMS = [
  'Room 101', 'Room 102', 'Room 103', 'Room 104',
  'Room 201', 'Room 202', 'Room 203', 'Room 204',
  'Room 301', 'Room 302', 'Room 303', 'Room 304'
]

export function ManageGrades() {
  const { users, classes, scores, updateUser, updateClass, refreshData } = useData()
  const { push } = useToast()
  
  // Step state: 1 (Setup/Intro), 2 (Phase 1: Graduation), 3 (Phase 2: Promote G11), 4 (Phase 3: Promote G10), 5 (Phase 4: Enroll New Hires), 6 (Summary)
  const [currentStep, setCurrentStep] = useState<1 | 2 | 3 | 4 | 5 | 6>(1)
  
  // DB school years (fetched from API)
  const [dbSchoolYears, setDbSchoolYears] = useState<ApiSchoolYear[]>([])

  // Selection school years — stored as the display name string
  const [selectedSourceYear, setSelectedSourceYear] = useState<string>('')
  const [selectedSourceYearId, setSelectedSourceYearId] = useState<number>(0)
  // Target year selected from a curated list (auto-suggested + existing DB years)
  const [selectedTargetYear, setSelectedTargetYear] = useState<string>('')
  const [selectedTargetYearId, setSelectedTargetYearId] = useState<number>(0)
  
  // Mappings
  const [mappingsG11, setMappingsG11] = useState<Record<string, string>>({})
  const [mappingsG10, setMappingsG10] = useState<Record<string, string>>({})
  const [newHiresMappings, setNewHiresMappings] = useState<Record<string, string>>({})
  
  // Class configuration overrides: classId -> { homeroomTeacher: string, room: string, studentLimit: number }
  const [classConfigs, setClassConfigs] = useState<Record<string, { homeroomTeacher: string, room: string, studentLimit: number }>>({})
  
  const [isProcessing, setIsProcessing] = useState(false)
  const [summary, setSummary] = useState({
    graduatedCount: 0,
    promotedG11Count: 0,
    promotedG10Count: 0,
    enrolledNewHiresCount: 0,
    targetYear: '',
  })

  // Exclusion lists
  const [excludedGraduationEmails, setExcludedGraduationEmails] = useState<string[]>([])
  const [excludedG11Emails, setExcludedG11Emails] = useState<string[]>([])
  const [excludedG10Emails, setExcludedG10Emails] = useState<string[]>([])
  const [excludedNewHireEmails, setExcludedNewHireEmails] = useState<string[]>([])

  const students = useMemo(() => users.filter((u) => u.role === 'student'), [users])

  /** Given a year name like "2025-2026", return "2026-2027" */
  const suggestNextYear = (yearName: string): string => {
    const parts = yearName.split('-')
    if (parts.length === 2) {
      const end = parseInt(parts[1], 10)
      if (!isNaN(end)) return `${end}-${end + 1}`
    }
    return ''
  }

  const getStudentGpa = (email: string) => {
    const studentScores = scores.filter((s) => s.studentEmail === email)
    if (studentScores.length === 0) return 8.0
    const sum = studentScores.reduce((acc, curr) => acc + curr.scoreReceived, 0)
    return Number((sum / studentScores.length).toFixed(2))
  }

  // Candidates list
  const graduationCandidates = useMemo(() => {
    return students.filter(s => {
      if (!s.classId) return false
      const c = classes.find(cl => cl.id === s.classId)
      return c?.year === selectedSourceYear && c.grade === 12 && s.status !== 'GRADUATED'
    })
  }, [students, classes, selectedSourceYear])

  const g11Candidates = useMemo(() => {
    return students.filter(s => {
      if (!s.classId) return false
      const c = classes.find(cl => cl.id === s.classId)
      return c?.year === selectedSourceYear && c.grade === 11
    })
  }, [students, classes, selectedSourceYear])

  const g10Candidates = useMemo(() => {
    return students.filter(s => {
      if (!s.classId) return false
      const c = classes.find(cl => cl.id === s.classId)
      return c?.year === selectedSourceYear && c.grade === 10
    })
  }, [students, classes, selectedSourceYear])

  const newHireCandidates = useMemo(() => {
    return students.filter(s => s.status === 'PENDING_GRADE_ASSIGNMENT' || (!s.classId && !s.grade))
  }, [students])

  // Fetch real school years from API on mount
  useEffect(() => {
    getSchoolYears().then(years => {
      const sorted = [...years].sort((a, b) => b.name.localeCompare(a.name))
      setDbSchoolYears(sorted)
      if (sorted.length > 0 && !selectedSourceYear) {
        const currentYear = sorted.find(y => y.isCurrent) || sorted[0]
        setSelectedSourceYear(currentYear.name)
        setSelectedSourceYearId(currentYear.schoolYearId)
        // Auto-suggest next target year name
        if (!selectedTargetYear) {
          const suggested = suggestNextYear(currentYear.name)
          setSelectedTargetYear(suggested)
        }
      }
    }).catch(console.error)
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Pre-load class configs
  useEffect(() => {
    if (!selectedTargetYear) return
    const initialConfigs: Record<string, { homeroomTeacher: string, room: string, studentLimit: number }> = {}
    classes.forEach(c => {
      if (c.year === selectedTargetYear) {
        initialConfigs[c.id] = {
          homeroomTeacher: c.homeroomTeacher ?? '',
          room: c.room ?? '',
          studentLimit: c.studentLimit ?? 20,
        }
      }
    })
    setClassConfigs(initialConfigs)
  }, [classes, selectedTargetYear])

  // Classes list filtered by grade for target mappings
  const sourceClassesG11 = useMemo(() => {
    return classes.filter(c => c.year === selectedSourceYear && c.grade === 11)
  }, [classes, selectedSourceYear])

  const sourceClassesG10 = useMemo(() => {
    return classes.filter(c => c.year === selectedSourceYear && c.grade === 10)
  }, [classes, selectedSourceYear])

  const targetClassesG12 = useMemo(() => {
    return classes.filter(c => c.year === selectedTargetYear && c.grade === 12)
  }, [classes, selectedTargetYear])

  const targetClassesG11 = useMemo(() => {
    return classes.filter(c => c.year === selectedTargetYear && c.grade === 11)
  }, [classes, selectedTargetYear])

  const targetClassesG10 = useMemo(() => {
    return classes.filter(c => c.year === selectedTargetYear && c.grade === 10)
  }, [classes, selectedTargetYear])

  // Auto-mappings G11 -> G12
  useEffect(() => {
    if (sourceClassesG11.length === 0 || targetClassesG12.length === 0) return
    const mappings: Record<string, string> = {}
    sourceClassesG11.forEach((sc, idx) => {
      const matchingTarget = targetClassesG12.find(tc => tc.name.replace('12', '') === sc.name.replace('11', ''))
      mappings[sc.id] = matchingTarget?.id || targetClassesG12[Math.min(idx, targetClassesG12.length - 1)].id
    })
    setMappingsG11(mappings)
  }, [sourceClassesG11, targetClassesG12])

  // Auto-mappings G10 -> G11
  useEffect(() => {
    if (sourceClassesG10.length === 0 || targetClassesG11.length === 0) return
    const mappings: Record<string, string> = {}
    sourceClassesG10.forEach((sc, idx) => {
      const matchingTarget = targetClassesG11.find(tc => tc.name.replace('11', '') === sc.name.replace('10', ''))
      mappings[sc.id] = matchingTarget?.id || targetClassesG11[Math.min(idx, targetClassesG11.length - 1)].id
    })
    setMappingsG10(mappings)
  }, [sourceClassesG10, targetClassesG11])

  // Default mappings for new hires
  useEffect(() => {
    if (newHireCandidates.length === 0 || targetClassesG10.length === 0) return
    const mappings: Record<string, string> = {}
    newHireCandidates.forEach(s => {
      mappings[s.email] = targetClassesG10[0].id
    })
    setNewHiresMappings(mappings)
  }, [newHireCandidates, targetClassesG10])

  // Filter free teachers dynamically
  const getAvailableTeachers = (currentClassId: string) => {
    const allTeachers = users.filter(u => u.role === 'teacher')
    const dbAssignedTeachers = new Set(
      classes
        .filter(c => c.year === selectedTargetYear && c.id !== currentClassId && c.homeroomTeacher)
        .map(c => c.homeroomTeacher)
    )
    const wizardAssignedTeachers = new Set<string>()
    Object.entries(classConfigs).forEach(([id, config]) => {
      if (id !== currentClassId && config.homeroomTeacher) {
        wizardAssignedTeachers.add(config.homeroomTeacher)
      }
    })
    return allTeachers.filter(
      t => !dbAssignedTeachers.has(t.email) && !wizardAssignedTeachers.has(t.email)
    )
  }

  // Filter free classrooms dynamically
  const getAvailableRooms = (currentClassId: string) => {
    const dbAssignedRooms = new Set(
      classes
        .filter(c => c.year === selectedTargetYear && c.id !== currentClassId && c.room)
        .map(c => c.room)
    )
    const wizardAssignedRooms = new Set<string>()
    Object.entries(classConfigs).forEach(([id, config]) => {
      if (id !== currentClassId && config.room) {
        wizardAssignedRooms.add(config.room)
      }
    })
    return AVAILABLE_ROOMS.filter(
      r => !dbAssignedRooms.has(r) && !wizardAssignedRooms.has(r)
    )
  }

  // Filter target classes that are not already mapped by another source class
  const getAvailableTargetClasses = (
    allTargets: typeof classes,
    currentSourceId: string,
    mappings: Record<string, string>,
  ) => {
    const selectedByOthers = new Set(
      Object.entries(mappings)
        .filter(([srcId]) => srcId !== currentSourceId)
        .map(([, targetId]) => targetId)
    )
    return allTargets.filter(tc => !selectedByOthers.has(tc.id))
  }

  // Get current active capacities in wizard step
  const getMappedClassCounts = (phase: 'G11' | 'G10' | 'NEWHIRES') => {
    const counts: Record<string, number> = {}
    classes.forEach(c => {
      if (c.year === selectedTargetYear) {
        counts[c.id] = 0
      }
    })

    if (phase === 'G11') {
      const activeCandidates = g11Candidates.filter(s => !excludedG11Emails.includes(s.email))
      activeCandidates.forEach(s => {
        const targetId = mappingsG11[s.classId || '']
        if (targetId) counts[targetId] = (counts[targetId] || 0) + 1
      })
    } else if (phase === 'G10') {
      const activeCandidates = g10Candidates.filter(s => !excludedG10Emails.includes(s.email))
      activeCandidates.forEach(s => {
        const targetId = mappingsG10[s.classId || '']
        if (targetId) counts[targetId] = (counts[targetId] || 0) + 1
      })
    } else if (phase === 'NEWHIRES') {
      const activeCandidates = newHireCandidates.filter(s => !excludedNewHireEmails.includes(s.email))
      activeCandidates.forEach(s => {
        const targetId = newHiresMappings[s.email]
        if (targetId) counts[targetId] = (counts[targetId] || 0) + 1
      })
    }
    return counts
  }

  // Check if any mapped class exceeds student limits
  const hasExceededLimits = (phase: 'G11' | 'G10' | 'NEWHIRES') => {
    const counts = getMappedClassCounts(phase)
    return Object.entries(counts).some(([cid, count]) => {
      const limit = classConfigs[cid]?.studentLimit ?? 20
      return count > limit
    })
  }

  // --- Handlers ---
  const handleStartRollover = async () => {
    if (selectedSourceYear === selectedTargetYear) {
      push('error', 'Source year and Target year must be different.')
      return
    }
    setIsProcessing(true)
    try {
      // 1. Ensure target year exists in DB
      const targetYearRecord = await findOrCreateSchoolYear(selectedTargetYear)
      const targetYearId = targetYearRecord.schoolYearId
      setSelectedTargetYearId(targetYearId)

      // 2. Fetch fresh classes from API to prevent duplicate key violations
      const freshApiClasses = await getClasses()

      // Create target classes by copying from source year
      const sourceClasses = classes.filter(c => c.year === selectedSourceYear)
      
      if (sourceClasses.length === 0) {
        throw new Error(`No source classes found in year ${selectedSourceYear} to roll over.`)
      }

      let createdCount = 0
      for (const sc of sourceClasses) {
        let targetGradeId = 1
        let targetName = sc.name

        if (sc.grade === 10) {
          targetGradeId = 2 // G11
          targetName = sc.name.replace('10', '11')
        } else if (sc.grade === 11) {
          targetGradeId = 3 // G12
          targetName = sc.name.replace('11', '12')
        } else if (sc.grade === 12) {
          targetGradeId = 1 // G10
          targetName = sc.name.replace('12', '10')
        }

        // Check if this class already exists in the database
        const alreadyExists = freshApiClasses.some(ec => 
          ec.schoolYearId === targetYearId && 
          ec.name === targetName && 
          ec.trainingProgram === 'REGULAR'
        )

        if (!alreadyExists) {
          await createApiClass({
            schoolYearId: targetYearId,
            gradeId: targetGradeId,
            name: targetName,
            homeroomTeacherId: null,
            room: '',
            studentLimit: 20, // default limit is 20
            trainingProgram: 'REGULAR',
            isActive: true
          })
          createdCount++
        }
      }

      // Trigger context refresh to reload new classes
      refreshData()
      if (createdCount > 0) {
        push('success', `Initialized ${createdCount} classes for ${selectedTargetYear} with 20 student limit default.`)
      }

      setCurrentStep(2)
    } catch (err: any) {
      push('error', err?.message || 'Failed to initialize rollover.')
      console.error(err)
    } finally {
      setIsProcessing(false)
    }
  }

  const executeGraduation = async () => {
    setIsProcessing(true)
    try {
      const candidates = graduationCandidates.filter(s => !excludedGraduationEmails.includes(s.email))
      if (candidates.length === 0) {
        push('info', 'No candidates selected for graduation.')
        setCurrentStep(3)
        return
      }

      // Ensure target year exists in DB and get its ID
      const targetYearRecord = await findOrCreateSchoolYear(selectedTargetYear)
      setSelectedTargetYearId(targetYearRecord.schoolYearId)

      const studentIds = candidates.map(s => s.userId || '').filter(Boolean)
      const mappings = Array.from(new Set(candidates.map(s => s.classId))).map(cid => ({
        sourceClassId: Number(cid),
        targetClassId: null
      }))

      await batchPromoteStudents({
        sourceSchoolYearId: selectedSourceYearId,
        targetSchoolYearId: targetYearRecord.schoolYearId,
        classMappings: mappings,
        studentIds
      })

      candidates.forEach(s => {
        updateUser(s.email, { grade: 12, classId: undefined })
      })

      setSummary(prev => ({ ...prev, graduatedCount: candidates.length }))
      push('success', `Graduated ${candidates.length} student(s) successfully.`)
      setCurrentStep(3)
    } catch (err: any) {
      push('error', err?.message || 'Failed to process graduation.')
      console.error(err)
    } finally {
      setIsProcessing(false)
    }
  }

  const executeG11Promotion = async () => {
    if (hasExceededLimits('G11')) {
      push('error', 'One or more target classes exceed their student limits. Please increase limits or balance assignments.')
      return
    }

    setIsProcessing(true)
    try {
      const candidates = g11Candidates.filter(s => !excludedG11Emails.includes(s.email))
      if (candidates.length === 0) {
        push('info', 'No candidates selected for G11 promotion.')
        setCurrentStep(4)
        return
      }

      const mappedG12Ids = new Set(Object.values(mappingsG11))
      for (const cid of Array.from(mappedG12Ids)) {
        const config = classConfigs[cid]
        const targetClass = classes.find(c => c.id === cid)
        if (config && targetClass) {
          if (!config.homeroomTeacher || !config.room) {
            throw new Error(`Target class ${targetClass.name} must have a homeroom teacher and room assigned.`);
          }
          const teacherUser = users.find(u => u.email === config.homeroomTeacher)
          const teacherId = teacherUser?.userId
          
          await updateApiClass(Number(cid), {
            name: targetClass.name,
            gradeId: 3, // Grade 12
            schoolYearId: selectedTargetYearId,
            homeroomTeacherId: teacherId || undefined,
            room: config.room || undefined,
            studentLimit: config.studentLimit,
          })

          updateClass(cid, {
            homeroomTeacher: config.homeroomTeacher || undefined,
            room: config.room,
            studentLimit: config.studentLimit
          })
        }
      }

      const classMappings = Object.entries(mappingsG11).map(([sourceId, targetId]) => ({
        sourceClassId: Number(sourceId),
        targetClassId: Number(targetId)
      }))

      const studentIds = candidates.map(s => s.userId || '').filter(Boolean)

      await batchPromoteStudents({
        sourceSchoolYearId: selectedSourceYearId,
        targetSchoolYearId: selectedTargetYearId,
        classMappings,
        studentIds
      })

      candidates.forEach(s => {
        const targetId = mappingsG11[s.classId || '']
        updateUser(s.email, { grade: 12, classId: targetId })
      })

      setSummary(prev => ({ ...prev, promotedG11Count: candidates.length }))
      push('success', `Promoted ${candidates.length} Grade 11 student(s) to Grade 12.`)
      setCurrentStep(4)
    } catch (err: any) {
      push('error', err?.message || 'Failed to promote G11 students.')
      console.error(err)
    } finally {
      setIsProcessing(false)
    }
  }

  const executeG10Promotion = async () => {
    if (hasExceededLimits('G10')) {
      push('error', 'One or more target classes exceed their student limits. Please increase limits or balance assignments.')
      return
    }

    setIsProcessing(true)
    try {
      const candidates = g10Candidates.filter(s => !excludedG10Emails.includes(s.email))
      if (candidates.length === 0) {
        push('info', 'No candidates selected for G10 promotion.')
        setCurrentStep(5)
        return
      }

      const mappedG11Ids = new Set(Object.values(mappingsG10))
      for (const cid of Array.from(mappedG11Ids)) {
        const config = classConfigs[cid]
        const targetClass = classes.find(c => c.id === cid)
        if (config && targetClass) {
          if (!config.homeroomTeacher || !config.room) {
            throw new Error(`Target class ${targetClass.name} must have a homeroom teacher and room assigned.`);
          }
          const teacherUser = users.find(u => u.email === config.homeroomTeacher)
          const teacherId = teacherUser?.userId
          
          await updateApiClass(Number(cid), {
            name: targetClass.name,
            gradeId: 2, // Grade 11
            schoolYearId: selectedTargetYearId,
            homeroomTeacherId: teacherId || undefined,
            room: config.room || undefined,
            studentLimit: config.studentLimit,
          })

          updateClass(cid, {
            homeroomTeacher: config.homeroomTeacher || undefined,
            room: config.room,
            studentLimit: config.studentLimit
          })
        }
      }

      const classMappings = Object.entries(mappingsG10).map(([sourceId, targetId]) => ({
        sourceClassId: Number(sourceId),
        targetClassId: Number(targetId)
      }))

      const studentIds = candidates.map(s => s.userId || '').filter(Boolean)

      await batchPromoteStudents({
        sourceSchoolYearId: selectedSourceYearId,
        targetSchoolYearId: selectedTargetYearId,
        classMappings,
        studentIds
      })

      candidates.forEach(s => {
        const targetId = mappingsG10[s.classId || '']
        updateUser(s.email, { grade: 11, classId: targetId })
      })

      setSummary(prev => ({ ...prev, promotedG10Count: candidates.length }))
      push('success', `Promoted ${candidates.length} Grade 10 student(s) to Grade 11.`)
      setCurrentStep(5)
    } catch (err: any) {
      push('error', err?.message || 'Failed to promote G10 students.')
      console.error(err)
    } finally {
      setIsProcessing(false)
    }
  }

  const executeNewHireEnrollment = async () => {
    if (hasExceededLimits('NEWHIRES')) {
      push('error', 'One or more target classes exceed their student limits. Please increase limits or balance assignments.')
      return
    }

    setIsProcessing(true)
    try {
      const candidates = newHireCandidates.filter(s => !excludedNewHireEmails.includes(s.email))
      if (candidates.length === 0) {
        push('info', 'No new hires selected for enrollment.')
        setSummary(prev => ({ ...prev, targetYear: selectedTargetYear }))
        setCurrentStep(6)
        return
      }

      const targetClassIds = Array.from(new Set(candidates.map(s => newHiresMappings[s.email]).filter(Boolean)))
      if (targetClassIds.length === 0) {
        push('error', 'Select a target class for at least one student.')
        setIsProcessing(false)
        return
      }

      for (const cid of targetClassIds) {
        const config = classConfigs[cid]
        const targetClass = classes.find(c => c.id === cid)
        if (config && targetClass) {
          if (!config.homeroomTeacher || !config.room) {
            throw new Error(`Target class ${targetClass.name} must have a homeroom teacher and room assigned.`);
          }
          const teacherUser = users.find(u => u.email === config.homeroomTeacher)
          const teacherId = teacherUser?.userId
          
          await updateApiClass(Number(cid), {
            name: targetClass.name,
            gradeId: 1, // Grade 10
            schoolYearId: selectedTargetYearId,
            homeroomTeacherId: teacherId || undefined,
            room: config.room || undefined,
            studentLimit: config.studentLimit,
          })

          updateClass(cid, {
            homeroomTeacher: config.homeroomTeacher || undefined,
            room: config.room,
            studentLimit: config.studentLimit
          })
        }
      }

      const studentsByTargetClass = new Map<string, string[]>()
      candidates.forEach(s => {
        const targetId = newHiresMappings[s.email]
        if (targetId) {
          if (!studentsByTargetClass.has(targetId)) {
            studentsByTargetClass.set(targetId, [])
          }
          studentsByTargetClass.get(targetId)!.push(s.userId || s.email)
        }
      })

      for (const [targetClassId, studentIds] of studentsByTargetClass.entries()) {
        const targetClass = classes.find(c => c.id === targetClassId)
        await batchAssignGradeAndClass({
          studentIds,
          gradeLevel: 10,
          targetClassId: Number(targetClassId),
          schoolYearId: selectedTargetYearId
        })

        candidates.forEach(s => {
          if (newHiresMappings[s.email] === targetClassId) {
            updateUser(s.email, { grade: 10, classId: targetClass?.id, status: 'ACTIVE' })
          }
        })
      }

      setSummary(prev => ({
        ...prev,
        enrolledNewHiresCount: candidates.length,
        targetYear: selectedTargetYear
      }))
      push('success', `Enrolled ${candidates.length} new hire student(s) successfully.`)
      setCurrentStep(6)
    } catch (err: any) {
      push('error', err?.message || 'Failed to enroll new hires.')
      console.error(err)
    } finally {
      setIsProcessing(false)
    }
  }

  // Active mapping limits calculation
  const mappedCountsG11 = getMappedClassCounts('G11')
  const mappedCountsG10 = getMappedClassCounts('G10')
  const mappedCountsNewHires = getMappedClassCounts('NEWHIRES')

  return (
    <div className="space-y-6">
      {/* 6-Step Process Stepper */}
      <div className="bg-white border border-slate-200 rounded-lg p-5 shadow-sm">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          {([
            { step: 1, label: '1. Setup', desc: 'Rollover Parameters' },
            { step: 2, label: '2. Graduation', desc: 'Graduate G12s' },
            { step: 3, label: '3. Promote G11', desc: 'G11 ➜ G12 Classes' },
            { step: 4, label: '4. Promote G10', desc: 'G10 ➜ G11 Classes' },
            { step: 5, label: '5. New Hires', desc: 'Allocate New Hires' },
            { step: 6, label: '6. Summary', desc: 'Rollover Impact Report' }
          ] as const).map((s) => {
            const isActive = currentStep === s.step
            const isCompleted = currentStep > s.step
            return (
              <div key={s.step} className="flex items-center gap-3 flex-grow">
                <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-sm font-bold border transition-all ${
                  isActive 
                    ? 'bg-indigo-600 border-indigo-600 text-white shadow-md ring-4 ring-indigo-50'
                    : isCompleted 
                      ? 'bg-emerald-500 border-emerald-500 text-white'
                      : 'bg-slate-50 border-slate-200 text-slate-500'
                }`}>
                  {isCompleted ? '✓' : s.step}
                </span>
                <div>
                  <h4 className={`text-sm font-semibold ${isActive ? 'text-indigo-600' : 'text-slate-700'}`}>{s.label}</h4>
                  <p className="text-xs text-slate-400 font-light">{s.desc}</p>
                </div>
                {s.step < 6 && <div className="hidden lg:block h-[1px] bg-slate-200 flex-grow mx-4" />}
              </div>
            )
          })}
        </div>
      </div>

      {currentStep === 1 && (
        <Card title="Year-End Rollover Setup" description="Begin the single unified workflow to roll over classes and assign fresh resource allocations.">
          <div className="space-y-6">
            <div className="bg-indigo-50 border border-indigo-100 rounded-lg p-4 text-sm text-indigo-800">
              <span className="font-bold">Rollover Workflow Protocol:</span>
              <ul className="list-disc pl-5 mt-2 space-y-1">
                <li>Graduating G12 students immediately releases occupied homeroom teachers and classrooms.</li>
                <li>When mapping junior grades, the homeroom selection dynamically hides occupied teachers.</li>
                <li>Transitions validate class student limit boundaries to prevent overcrowding.</li>
              </ul>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Source School Year (Old)</label>
                <select
                  className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  value={selectedSourceYear}
                  onChange={(e) => {
                    const chosen = dbSchoolYears.find(y => y.name === e.target.value)
                    setSelectedSourceYear(e.target.value)
                    setSelectedSourceYearId(chosen?.schoolYearId ?? 0)
                    // Auto-suggest next target year
                    setSelectedTargetYear(suggestNextYear(e.target.value))
                    setSelectedTargetYearId(0)
                  }}
                >
                  {dbSchoolYears.map(y => (
                    <option key={y.schoolYearId} value={y.name}>{y.name}{y.isCurrent ? ' (Current)' : ''}</option>
                  ))}
                </select>
                <p className="text-xs text-slate-400 mt-1">School years with existing classes</p>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Target School Year (New)</label>
                <select
                  className="w-full border border-slate-300 rounded-md px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  value={selectedTargetYear}
                  onChange={(e) => {
                    const existing = dbSchoolYears.find(y => y.name === e.target.value)
                    setSelectedTargetYear(e.target.value)
                    // If the selected year already exists in DB, capture its ID now;
                    // otherwise leave 0 — find-or-create will assign the ID on execution.
                    setSelectedTargetYearId(existing?.schoolYearId ?? 0)
                  }}
                >
                  {/* Auto-suggested next year always appears first */}
                  {(() => {
                    const suggested = suggestNextYear(selectedSourceYear)
                    const existingNames = new Set(dbSchoolYears.map(y => y.name))
                    const options: string[] = []
                    if (suggested) options.push(suggested)
                    dbSchoolYears
                      .filter(y => y.name !== selectedSourceYear && y.name !== suggested)
                      .forEach(y => options.push(y.name))
                    return options.map(name => (
                      <option key={name} value={name}>
                        {name}{!existingNames.has(name) ? ' (new — will be created)' : ''}
                      </option>
                    ))
                  })()}
                </select>
                <p className="text-xs text-slate-400 mt-1">Select the year students will be promoted into</p>
              </div>
            </div>

            <div className="flex justify-end pt-4 border-t border-slate-100">
              <button
                type="button"
                onClick={handleStartRollover}
                disabled={isProcessing}
                className="bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-300 text-white font-semibold rounded-md px-6 py-2.5 cursor-pointer shadow-xs transition-all flex items-center gap-2"
              >
                {isProcessing ? (
                  <>
                    <span className="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-2"></span>
                    Initializing...
                  </>
                ) : (
                  'Start Rollover Workflow ➜'
                )}
              </button>
            </div>
          </div>
        </Card>
      )}

      {currentStep === 2 && (
        <Card title="Phase 1: Graduate Grade 12" description="Graduate the Grade 12 students to release homeroom teacher resources and classrooms.">
          <div className="space-y-4">
            <div className="flex justify-between items-center bg-slate-50 border border-slate-200 rounded-lg px-4 py-3">
              <span className="text-sm font-medium text-slate-700">
                Candidates: <strong className="text-indigo-600">{graduationCandidates.filter(s => !excludedGraduationEmails.includes(s.email)).length}</strong> / <strong>{graduationCandidates.length}</strong>
              </span>
              <button
                type="button"
                onClick={() => {
                  if (excludedGraduationEmails.length === 0) {
                    setExcludedGraduationEmails(graduationCandidates.map(s => s.email))
                  } else {
                    setExcludedGraduationEmails([])
                  }
                }}
                className="text-sm font-semibold text-indigo-600 hover:text-indigo-800"
              >
                {excludedGraduationEmails.length === 0 ? 'Exclude All' : 'Include All'}
              </button>
            </div>

            <div className="overflow-x-auto border border-slate-200 rounded-lg">
              <table className="min-w-full divide-y divide-slate-200 text-sm">
                <thead className="bg-slate-50">
                  <tr>
                    <th className="px-4 py-3 text-center w-12 font-semibold text-slate-700">#</th>
                    <th className="px-4 py-3 text-left font-semibold text-slate-700">Student Info</th>
                    <th className="px-4 py-3 text-center font-semibold text-slate-700">GPA</th>
                    <th className="px-4 py-3 text-center font-semibold text-slate-700">Current Class</th>
                    <th className="px-4 py-3 text-center w-24 font-semibold text-slate-700">Include</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200 bg-white">
                  {graduationCandidates.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="px-4 py-8 text-center text-slate-500">
                        No Grade 12 candidates found in {selectedSourceYear}.
                      </td>
                    </tr>
                  ) : (
                    graduationCandidates.map((student, index) => {
                      const isIncluded = !excludedGraduationEmails.includes(student.email)
                      const gpa = getStudentGpa(student.email)
                      return (
                        <tr key={student.email} className={`hover:bg-slate-50/50 transition-colors ${!isIncluded ? 'opacity-50' : ''}`}>
                          <td className="px-4 py-3 text-slate-400 font-mono text-center text-xs">{index + 1}</td>
                          <td className="px-4 py-3">
                            <div className="font-semibold text-slate-900">{student.fullName}</div>
                            <div className="text-xs text-slate-500">{student.email}</div>
                          </td>
                          <td className="px-4 py-3 text-center font-bold font-mono text-slate-800">{gpa}</td>
                          <td className="px-4 py-3 text-center">
                            <span className="px-2 py-1 bg-slate-100 rounded-md text-xs text-slate-600 font-medium">
                              {classes.find(c => c.id === student.classId)?.name || 'Grade 12'}
                            </span>
                          </td>
                          <td className="px-4 py-3 text-center">
                            <input
                              type="checkbox"
                              checked={isIncluded}
                              onChange={() => {
                                setExcludedGraduationEmails(prev =>
                                  prev.includes(student.email)
                                    ? prev.filter(e => e !== student.email)
                                    : [...prev, student.email]
                                )
                              }}
                              className="h-4 w-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500 cursor-pointer"
                            />
                          </td>
                        </tr>
                      )
                    })
                  )}
                </tbody>
              </table>
            </div>

            <div className="flex justify-between items-center pt-4 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setCurrentStep(1)}
                className="border border-slate-300 hover:bg-slate-50 text-slate-700 font-semibold rounded-md px-4 py-2 cursor-pointer transition-all"
              >
                ⏴ Back
              </button>

              <button
                type="button"
                onClick={executeGraduation}
                disabled={isProcessing}
                className="bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-300 text-white font-semibold rounded-md px-6 py-2.5 flex items-center gap-2 cursor-pointer transition-all shadow-xs"
              >
                {isProcessing ? (
                  <>
                    <span className="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-2"></span>
                    Processing...
                  </>
                ) : (
                  `Execute Graduation (${graduationCandidates.filter(s => !excludedGraduationEmails.includes(s.email)).length}) 🎓`
                )}
              </button>
            </div>
          </div>
        </Card>
      )}

      {currentStep === 3 && (
        <Card title="Phase 2: Promote Grade 11 to Grade 12" description="Map G11 classes to new G12 classes, allocate released teacher/room resources, and set limits.">
          <div className="space-y-6">
            <div className="space-y-4">
              <h3 className="font-semibold text-slate-900 text-sm border-b border-slate-100 pb-2">Class Mappings & Resource Allocation</h3>
              {sourceClassesG11.length === 0 ? (
                <p className="text-sm text-slate-500">No Grade 11 source classes found in {selectedSourceYear}.</p>
              ) : (
                sourceClassesG11.map(sc => {
                  const targetClassId = mappingsG11[sc.id] || ''
                  const config = classConfigs[targetClassId] || { homeroomTeacher: '', room: '', studentLimit: 20 }
                  const availableTeachers = getAvailableTeachers(targetClassId)
                  const matchingClass = classes.find(c => c.id === targetClassId)
                  const allocatedCount = mappedCountsG11[targetClassId] ?? 0
                  const isOver = allocatedCount > config.studentLimit
                  
                  return (
                    <div key={sc.id} className={`border rounded-lg p-4 bg-slate-50/50 space-y-3 shadow-xs ${isOver ? 'border-rose-300 bg-rose-50/20' : 'border-slate-200'}`}>
                      <div className="flex justify-between items-center border-b border-slate-100 pb-2">
                        <h4 className="font-bold text-slate-800 text-sm">Source Class: {sc.name}</h4>
                        <div className="text-xs font-semibold">
                          <span className="text-slate-500 mr-2">({g11Candidates.filter(s => s.classId === sc.id).length} candidate students)</span>
                          <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${isOver ? 'bg-rose-100 text-rose-700' : 'bg-indigo-100 text-indigo-700'}`}>
                            Mapped: {allocatedCount} / {config.studentLimit} Limit
                          </span>
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <FormField
                          as="select"
                          label="Target Class (G12)"
                          name={`targetClass-${sc.id}`}
                          value={targetClassId}
                          onChange={(e) => {
                            const val = e.target.value
                            setMappingsG11(prev => ({ ...prev, [sc.id]: val }))
                          }}
                        >
                          <option value="">Select target class</option>
                          {getAvailableTargetClasses(targetClassesG12, sc.id, mappingsG11).map(tc => (
                            <option key={tc.id} value={tc.id}>{tc.name}</option>
                          ))}
                        </FormField>

                        <FormField
                          as="select"
                          label="Homeroom Teacher"
                          name={`teacher-${sc.id}`}
                          value={config.homeroomTeacher}
                          disabled={!targetClassId}
                          onChange={(e) => {
                            const val = e.target.value
                            setClassConfigs(prev => ({
                              ...prev,
                              [targetClassId]: { ...prev[targetClassId], homeroomTeacher: val }
                            }))
                          }}
                        >
                          <option value="">Select Homeroom Teacher</option>
                          {matchingClass?.homeroomTeacher && (
                            <option value={matchingClass.homeroomTeacher}>
                              {users.find(u => u.email === matchingClass.homeroomTeacher)?.fullName || matchingClass.homeroomTeacher} (Current)
                            </option>
                          )}
                          {availableTeachers.map(t => (
                            <option key={t.email} value={t.email}>{t.fullName} ({t.subject})</option>
                          ))}
                        </FormField>

                        <FormField
                          as="select"
                          label="Classroom Room"
                          name={`room-${sc.id}`}
                          value={config.room}
                          disabled={!targetClassId}
                          onChange={(e) => {
                            const val = e.target.value
                            setClassConfigs(prev => ({
                              ...prev,
                              [targetClassId]: { ...prev[targetClassId], room: val }
                            }))
                          }}
                        >
                          <option value="">Select Room</option>
                          {matchingClass?.room && (
                            <option value={matchingClass.room}>{matchingClass.room} (Current)</option>
                          )}
                          {getAvailableRooms(targetClassId).map(r => (
                            <option key={r} value={r}>{r}</option>
                          ))}
                        </FormField>

                        <FormField
                          type="number"
                          label="Student Limit"
                          name={`limit-${sc.id}`}
                          value={String(config.studentLimit)}
                          disabled={!targetClassId}
                          onChange={(e) => {
                            const val = Number(e.target.value)
                            setClassConfigs(prev => ({
                              ...prev,
                              [targetClassId]: { ...prev[targetClassId], studentLimit: val }
                            }))
                          }}
                        />
                      </div>
                    </div>
                  )
                })
              )}
            </div>

            {/* Student checklist for G11 Promotion */}
            <div className="space-y-4">
              <h3 className="font-semibold text-slate-900 text-sm border-b border-slate-100 pb-2">Student Checklist (Exclude Exceptions)</h3>
              <div className="flex justify-between items-center bg-slate-50 border border-slate-200 rounded-lg px-4 py-2">
                <span className="text-xs font-medium text-slate-700">
                  Included: <strong className="text-indigo-600">{g11Candidates.filter(s => !excludedG11Emails.includes(s.email)).length}</strong> / <strong>{g11Candidates.length}</strong>
                </span>
                <button
                  type="button"
                  onClick={() => {
                    if (excludedG11Emails.length === 0) {
                      setExcludedG11Emails(g11Candidates.map(s => s.email))
                    } else {
                      setExcludedG11Emails([])
                    }
                  }}
                  className="text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                >
                  {excludedG11Emails.length === 0 ? 'Exclude All' : 'Include All'}
                </button>
              </div>

              <div className="overflow-x-auto border border-slate-200 rounded-lg max-h-60 overflow-y-auto">
                <table className="min-w-full divide-y divide-slate-200 text-xs">
                  <thead className="bg-slate-50 sticky top-0">
                    <tr>
                      <th className="px-4 py-2 text-center w-12 font-semibold text-slate-700">#</th>
                      <th className="px-4 py-2 text-left font-semibold text-slate-700">Student Info</th>
                      <th className="px-4 py-2 text-center font-semibold text-slate-700">GPA</th>
                      <th className="px-4 py-2 text-center font-semibold text-slate-700">Current Class</th>
                      <th className="px-4 py-2 text-center font-semibold text-slate-700">Target Class (Mapped)</th>
                      <th className="px-4 py-2 text-center w-20 font-semibold text-slate-700">Include</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 bg-white">
                    {g11Candidates.length === 0 ? (
                      <tr>
                        <td colSpan={6} className="px-4 py-6 text-center text-slate-500">
                          No Grade 11 candidates found in {selectedSourceYear}.
                        </td>
                      </tr>
                    ) : (
                      g11Candidates.map((student, index) => {
                        const isIncluded = !excludedG11Emails.includes(student.email)
                        const gpa = getStudentGpa(student.email)
                        const currentClass = classes.find(c => c.id === student.classId)?.name || ''
                        const targetClassId = mappingsG11[student.classId || '']
                        const targetClass = classes.find(c => c.id === targetClassId)?.name || 'Not Mapped'
                        return (
                          <tr key={student.email} className={`hover:bg-slate-50/50 transition-colors ${!isIncluded ? 'opacity-50' : ''}`}>
                            <td className="px-4 py-2 text-slate-400 font-mono text-center">{index + 1}</td>
                            <td className="px-4 py-2">
                              <div className="font-semibold text-slate-900">{student.fullName}</div>
                              <div className="text-xxs text-slate-500">{student.email}</div>
                            </td>
                            <td className="px-4 py-2 text-center font-semibold">{gpa}</td>
                            <td className="px-4 py-2 text-center">{currentClass}</td>
                            <td className="px-4 py-2 text-center font-medium text-indigo-600">{targetClass}</td>
                            <td className="px-4 py-2 text-center">
                              <input
                                type="checkbox"
                                checked={isIncluded}
                                onChange={() => {
                                  setExcludedG11Emails(prev =>
                                    prev.includes(student.email)
                                      ? prev.filter(e => e !== student.email)
                                      : [...prev, student.email]
                                  )
                                }}
                                className="h-3.5 w-3.5 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500 cursor-pointer"
                              />
                            </td>
                          </tr>
                        )
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="flex justify-between items-center pt-4 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setCurrentStep(2)}
                className="border border-slate-300 hover:bg-slate-50 text-slate-700 font-semibold rounded-md px-4 py-2 cursor-pointer transition-all"
              >
                ⏴ Back
              </button>

              <button
                type="button"
                onClick={executeG11Promotion}
                disabled={isProcessing || sourceClassesG11.length === 0 || hasExceededLimits('G11')}
                className="bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-300 text-white font-semibold rounded-md px-6 py-2.5 flex items-center gap-2 cursor-pointer transition-all shadow-xs"
              >
                {isProcessing ? (
                  <>
                    <span className="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-2"></span>
                    Processing...
                  </>
                ) : (
                  `Execute Grade 11 Promotion (${g11Candidates.filter(s => !excludedG11Emails.includes(s.email)).length}) ⚡`
                )}
              </button>
            </div>
          </div>
        </Card>
      )}

      {currentStep === 4 && (
        <Card title="Phase 3: Promote Grade 10 to Grade 11" description="Map G10 classes to new G11 classes, allocate remaining homeroom teachers/rooms, and configure limits.">
          <div className="space-y-6">
            <div className="space-y-4">
              <h3 className="font-semibold text-slate-900 text-sm border-b border-slate-100 pb-2">Class Mappings & Resource Allocation</h3>
              {sourceClassesG10.length === 0 ? (
                <p className="text-sm text-slate-500">No Grade 10 source classes found in {selectedSourceYear}.</p>
              ) : (
                sourceClassesG10.map(sc => {
                  const targetClassId = mappingsG10[sc.id] || ''
                  const config = classConfigs[targetClassId] || { homeroomTeacher: '', room: '', studentLimit: 20 }
                  const availableTeachers = getAvailableTeachers(targetClassId)
                  const matchingClass = classes.find(c => c.id === targetClassId)
                  const allocatedCount = mappedCountsG10[targetClassId] ?? 0
                  const isOver = allocatedCount > config.studentLimit
                  
                  return (
                    <div key={sc.id} className={`border rounded-lg p-4 bg-slate-50/50 space-y-3 shadow-xs ${isOver ? 'border-rose-300 bg-rose-50/20' : 'border-slate-200'}`}>
                      <div className="flex justify-between items-center border-b border-slate-100 pb-2">
                        <h4 className="font-bold text-slate-800 text-sm">Source Class: {sc.name}</h4>
                        <div className="text-xs font-semibold">
                          <span className="text-slate-500 mr-2">({g10Candidates.filter(s => s.classId === sc.id).length} candidate students)</span>
                          <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${isOver ? 'bg-rose-100 text-rose-700' : 'bg-indigo-100 text-indigo-700'}`}>
                            Mapped: {allocatedCount} / {config.studentLimit} Limit
                          </span>
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                        <FormField
                          as="select"
                          label="Target Class (G11)"
                          name={`targetClass-${sc.id}`}
                          value={targetClassId}
                          onChange={(e) => {
                            const val = e.target.value
                            setMappingsG10(prev => ({ ...prev, [sc.id]: val }))
                          }}
                        >
                          <option value="">Select target class</option>
                          {getAvailableTargetClasses(targetClassesG11, sc.id, mappingsG10).map(tc => (
                            <option key={tc.id} value={tc.id}>{tc.name}</option>
                          ))}
                        </FormField>

                        <FormField
                          as="select"
                          label="Homeroom Teacher"
                          name={`teacher-${sc.id}`}
                          value={config.homeroomTeacher}
                          disabled={!targetClassId}
                          onChange={(e) => {
                            const val = e.target.value
                            setClassConfigs(prev => ({
                              ...prev,
                              [targetClassId]: { ...prev[targetClassId], homeroomTeacher: val }
                            }))
                          }}
                        >
                          <option value="">Select Homeroom Teacher</option>
                          {matchingClass?.homeroomTeacher && (
                            <option value={matchingClass.homeroomTeacher}>
                              {users.find(u => u.email === matchingClass.homeroomTeacher)?.fullName || matchingClass.homeroomTeacher} (Current)
                            </option>
                          )}
                          {availableTeachers.map(t => (
                            <option key={t.email} value={t.email}>{t.fullName} ({t.subject})</option>
                          ))}
                        </FormField>

                        <FormField
                          as="select"
                          label="Classroom Room"
                          name={`room-${sc.id}`}
                          value={config.room}
                          disabled={!targetClassId}
                          onChange={(e) => {
                            const val = e.target.value
                            setClassConfigs(prev => ({
                              ...prev,
                              [targetClassId]: { ...prev[targetClassId], room: val }
                            }))
                          }}
                        >
                          <option value="">Select Room</option>
                          {matchingClass?.room && (
                            <option value={matchingClass.room}>{matchingClass.room} (Current)</option>
                          )}
                          {getAvailableRooms(targetClassId).map(r => (
                            <option key={r} value={r}>{r}</option>
                          ))}
                        </FormField>

                        <FormField
                          type="number"
                          label="Student Limit"
                          name={`limit-${sc.id}`}
                          value={String(config.studentLimit)}
                          disabled={!targetClassId}
                          onChange={(e) => {
                            const val = Number(e.target.value)
                            setClassConfigs(prev => ({
                              ...prev,
                              [targetClassId]: { ...prev[targetClassId], studentLimit: val }
                            }))
                          }}
                        />
                      </div>
                    </div>
                  )
                })
              )}
            </div>

            {/* Student checklist for G10 Promotion */}
            <div className="space-y-4">
              <h3 className="font-semibold text-slate-900 text-sm border-b border-slate-100 pb-2">Student Checklist (Exclude Exceptions)</h3>
              <div className="flex justify-between items-center bg-slate-50 border border-slate-200 rounded-lg px-4 py-2">
                <span className="text-xs font-medium text-slate-700">
                  Included: <strong className="text-indigo-600">{g10Candidates.filter(s => !excludedG10Emails.includes(s.email)).length}</strong> / <strong>{g10Candidates.length}</strong>
                </span>
                <button
                  type="button"
                  onClick={() => {
                    if (excludedG10Emails.length === 0) {
                      setExcludedG10Emails(g10Candidates.map(s => s.email))
                    } else {
                      setExcludedG10Emails([])
                    }
                  }}
                  className="text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                >
                  {excludedG10Emails.length === 0 ? 'Exclude All' : 'Include All'}
                </button>
              </div>

              <div className="overflow-x-auto border border-slate-200 rounded-lg max-h-60 overflow-y-auto">
                <table className="min-w-full divide-y divide-slate-200 text-xs">
                  <thead className="bg-slate-50 sticky top-0">
                    <tr>
                      <th className="px-4 py-2 text-center w-12 font-semibold text-slate-700">#</th>
                      <th className="px-4 py-2 text-left font-semibold text-slate-700">Student Info</th>
                      <th className="px-4 py-2 text-center font-semibold text-slate-700">GPA</th>
                      <th className="px-4 py-2 text-center font-semibold text-slate-700">Current Class</th>
                      <th className="px-4 py-2 text-center font-semibold text-slate-700">Target Class (Mapped)</th>
                      <th className="px-4 py-2 text-center w-20 font-semibold text-slate-700">Include</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 bg-white">
                    {g10Candidates.length === 0 ? (
                      <tr>
                        <td colSpan={6} className="px-4 py-6 text-center text-slate-500">
                          No Grade 10 candidates found in {selectedSourceYear}.
                        </td>
                      </tr>
                    ) : (
                      g10Candidates.map((student, index) => {
                        const isIncluded = !excludedG10Emails.includes(student.email)
                        const gpa = getStudentGpa(student.email)
                        const currentClass = classes.find(c => c.id === student.classId)?.name || ''
                        const targetClassId = mappingsG10[student.classId || '']
                        const targetClass = classes.find(c => c.id === targetClassId)?.name || 'Not Mapped'
                        return (
                          <tr key={student.email} className={`hover:bg-slate-50/50 transition-colors ${!isIncluded ? 'opacity-50' : ''}`}>
                            <td className="px-4 py-2 text-slate-400 font-mono text-center">{index + 1}</td>
                            <td className="px-4 py-2">
                              <div className="font-semibold text-slate-900">{student.fullName}</div>
                              <div className="text-xxs text-slate-500">{student.email}</div>
                            </td>
                            <td className="px-4 py-2 text-center font-semibold">{gpa}</td>
                            <td className="px-4 py-2 text-center">{currentClass}</td>
                            <td className="px-4 py-2 text-center font-medium text-indigo-600">{targetClass}</td>
                            <td className="px-4 py-2 text-center">
                              <input
                                type="checkbox"
                                checked={isIncluded}
                                onChange={() => {
                                  setExcludedG10Emails(prev =>
                                    prev.includes(student.email)
                                      ? prev.filter(e => e !== student.email)
                                      : [...prev, student.email]
                                  )
                                }}
                                className="h-3.5 w-3.5 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500 cursor-pointer"
                              />
                            </td>
                          </tr>
                        )
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="flex justify-between items-center pt-4 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setCurrentStep(3)}
                className="border border-slate-300 hover:bg-slate-50 text-slate-700 font-semibold rounded-md px-4 py-2 cursor-pointer transition-all"
              >
                ⏴ Back
              </button>

              <button
                type="button"
                onClick={executeG10Promotion}
                disabled={isProcessing || sourceClassesG10.length === 0 || hasExceededLimits('G10')}
                className="bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-300 text-white font-semibold rounded-md px-6 py-2.5 flex items-center gap-2 cursor-pointer transition-all shadow-xs"
              >
                {isProcessing ? (
                  <>
                    <span className="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-2"></span>
                    Processing...
                  </>
                ) : (
                  `Execute Grade 10 Promotion (${g10Candidates.filter(s => !excludedG10Emails.includes(s.email)).length}) ⚡`
                )}
              </button>
            </div>
          </div>
        </Card>
      )}

      {currentStep === 5 && (
        <Card title="Phase 4: Enroll New Hires" description="Distribute unassigned/new students into target Grade 10 classes and configure their resources.">
          <div className="space-y-6">
            <div className="space-y-4">
              <h3 className="font-semibold text-slate-900 text-sm border-b border-slate-100 pb-2">Target Grade 10 Classes Configuration</h3>
              {targetClassesG10.length === 0 ? (
                <p className="text-sm text-slate-500">No target Grade 10 classes found in {selectedTargetYear}. Create them under the Classes tab first.</p>
              ) : (
                targetClassesG10.map(tc => {
                  const config = classConfigs[tc.id] || { homeroomTeacher: '', room: '', studentLimit: 20 }
                  const availableTeachers = getAvailableTeachers(tc.id)
                  const allocatedCount = mappedCountsNewHires[tc.id] ?? 0
                  const isOver = allocatedCount > config.studentLimit
                  
                  return (
                    <div key={tc.id} className={`border rounded-lg p-4 bg-slate-50/50 space-y-3 shadow-xs ${isOver ? 'border-rose-300 bg-rose-50/20' : 'border-slate-200'}`}>
                      <div className="flex justify-between items-center border-b border-slate-100 pb-2">
                        <h4 className="font-bold text-slate-800 text-sm">Target Class: {tc.name}</h4>
                        <div className="text-xs font-semibold">
                          <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${isOver ? 'bg-rose-100 text-rose-700' : 'bg-indigo-100 text-indigo-700'}`}>
                            Mapped: {allocatedCount} / {config.studentLimit} Limit
                          </span>
                        </div>
                      </div>
                      
                      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        <FormField
                          as="select"
                          label="Homeroom Teacher"
                          name={`teacher-${tc.id}`}
                          value={config.homeroomTeacher}
                          onChange={(e) => {
                            const val = e.target.value
                            setClassConfigs(prev => ({
                              ...prev,
                              [tc.id]: { ...prev[tc.id], homeroomTeacher: val }
                            }))
                          }}
                        >
                          <option value="">Select Homeroom Teacher</option>
                          {tc.homeroomTeacher && (
                            <option value={tc.homeroomTeacher}>
                              {users.find(u => u.email === tc.homeroomTeacher)?.fullName || tc.homeroomTeacher} (Current)
                            </option>
                          )}
                          {availableTeachers.map(t => (
                            <option key={t.email} value={t.email}>{t.fullName} ({t.subject})</option>
                          ))}
                        </FormField>

                        <FormField
                          as="select"
                          label="Classroom Room"
                          name={`room-${tc.id}`}
                          value={config.room}
                          onChange={(e) => {
                            const val = e.target.value
                            setClassConfigs(prev => ({
                              ...prev,
                              [tc.id]: { ...prev[tc.id], room: val }
                            }))
                          }}
                        >
                          <option value="">Select Room</option>
                          {tc.room && (
                            <option value={tc.room}>{tc.room} (Current)</option>
                          )}
                          {getAvailableRooms(tc.id).map(r => (
                            <option key={r} value={r}>{r}</option>
                          ))}
                        </FormField>

                        <FormField
                          type="number"
                          label="Student Limit"
                          name={`limit-${tc.id}`}
                          value={String(config.studentLimit)}
                          onChange={(e) => {
                            const val = Number(e.target.value)
                            setClassConfigs(prev => ({
                              ...prev,
                              [tc.id]: { ...prev[tc.id], studentLimit: val }
                            }))
                          }}
                        />
                      </div>
                    </div>
                  )
                })
              )}
            </div>

            <div className="space-y-4">
              <h3 className="font-semibold text-slate-900 text-sm border-b border-slate-100 pb-2">Student Allocation Check List</h3>
              <div className="overflow-x-auto border border-slate-200 rounded-lg max-h-72 overflow-y-auto">
                <table className="min-w-full divide-y divide-slate-200 text-sm">
                  <thead className="bg-slate-50 sticky top-0">
                    <tr>
                      <th className="px-4 py-2.5 text-center w-12 font-semibold text-slate-700">#</th>
                      <th className="px-4 py-2.5 text-left font-semibold text-slate-700">Student Name</th>
                      <th className="px-4 py-2.5 text-center font-semibold text-slate-700">Target Grade 10 Class Allocation</th>
                      <th className="px-4 py-2.5 text-center w-20 font-semibold text-slate-700">Include</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 bg-white">
                    {newHireCandidates.length === 0 ? (
                      <tr>
                        <td colSpan={4} className="px-4 py-8 text-center text-slate-500">
                          No pending new hire student records found.
                        </td>
                      </tr>
                    ) : (
                      newHireCandidates.map((student, index) => {
                        const isIncluded = !excludedNewHireEmails.includes(student.email)
                        const assignedClassId = newHiresMappings[student.email] || ''
                        return (
                          <tr key={student.email} className={`hover:bg-slate-50/50 transition-colors ${!isIncluded ? 'opacity-50' : ''}`}>
                            <td className="px-4 py-2 text-slate-400 font-mono text-center text-xs">{index + 1}</td>
                            <td className="px-4 py-2">
                              <div className="font-semibold text-slate-900">{student.fullName}</div>
                              <div className="text-xs text-slate-500">{student.email}</div>
                            </td>
                            <td className="px-4 py-2 text-center">
                              <select
                                value={assignedClassId}
                                disabled={!isIncluded}
                                onChange={(e) => {
                                  const val = e.target.value
                                  setNewHiresMappings(prev => ({ ...prev, [student.email]: val }))
                                }}
                                className="rounded-md border border-slate-300 px-3 py-1 text-xs focus:outline-none focus:ring-1 focus:ring-indigo-500 w-48"
                              >
                                <option value="">Select target class</option>
                                {targetClassesG10.map(tc => (
                                  <option key={tc.id} value={tc.id}>{tc.name}</option>
                                ))}
                              </select>
                            </td>
                            <td className="px-4 py-2 text-center">
                              <input
                                type="checkbox"
                                checked={isIncluded}
                                onChange={() => {
                                  setExcludedNewHireEmails(prev =>
                                    prev.includes(student.email)
                                      ? prev.filter(e => e !== student.email)
                                      : [...prev, student.email]
                                  )
                                }}
                                className="h-4 w-4 text-indigo-600 rounded border-slate-300 focus:ring-indigo-500 cursor-pointer"
                              />
                            </td>
                          </tr>
                        )
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            <div className="flex justify-between items-center pt-4 border-t border-slate-100">
              <button
                type="button"
                onClick={() => setCurrentStep(4)}
                className="border border-slate-300 hover:bg-slate-50 text-slate-700 font-semibold rounded-md px-4 py-2 cursor-pointer transition-all"
              >
                ⏴ Back
              </button>

              <button
                type="button"
                onClick={executeNewHireEnrollment}
                disabled={isProcessing || newHireCandidates.length === 0 || hasExceededLimits('NEWHIRES')}
                className="bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-300 text-white font-semibold rounded-md px-6 py-2.5 flex items-center gap-2 cursor-pointer transition-all shadow-xs"
              >
                {isProcessing ? (
                  <>
                    <span className="animate-spin inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full mr-2"></span>
                    Processing...
                  </>
                ) : (
                  `Execute Enrollment (${newHireCandidates.filter(s => !excludedNewHireEmails.includes(s.email)).length}) ⚡`
                )}
              </button>
            </div>
          </div>
        </Card>
      )}

      {currentStep === 6 && (
        <Card title="Unified Rollover Complete" description="The school year rollover has been completed successfully. Review the impact report details.">
          <div className="text-center py-8 space-y-6">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 text-3xl font-bold animate-bounce shadow-sm">
              ✓
            </div>
            <div>
              <h3 className="text-xl font-bold text-slate-900">Rollover Workflow Complete!</h3>
              <p className="text-slate-500 text-sm mt-1">All grade transitions, teacher assignments, and classroom limits have been mapped and saved.</p>
            </div>
            
            <div className="max-w-md mx-auto bg-slate-50 border border-slate-200 rounded-lg p-6 text-left space-y-3 shadow-xs">
              <h4 className="font-semibold text-slate-800 border-b border-slate-200 pb-2">Year-End Rollover Impact Report</h4>
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Target Year (New):</span>
                <span className="font-bold text-slate-900">{summary.targetYear}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Graduated (G12):</span>
                <span className="font-bold text-emerald-600">+{summary.graduatedCount} students</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Promoted G11 ➜ G12:</span>
                <span className="font-bold text-indigo-600">+{summary.promotedG11Count} students</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Promoted G10 ➜ G11:</span>
                <span className="font-bold text-indigo-600">+{summary.promotedG10Count} students</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-slate-500">Enrolled New Hires ➜ G10:</span>
                <span className="font-bold text-indigo-600">+{summary.enrolledNewHiresCount} students</span>
              </div>
            </div>

            <div className="pt-4 border-t border-slate-100 max-w-md mx-auto">
              <button
                type="button"
                onClick={() => {
                  setCurrentStep(1)
                  setSummary({ graduatedCount: 0, promotedG11Count: 0, promotedG10Count: 0, enrolledNewHiresCount: 0, targetYear: '' })
                }}
                className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold rounded-md px-6 py-2.5 transition-all cursor-pointer shadow-xs w-full"
              >
                Restart Rollover Workflow
              </button>
            </div>
          </div>
        </Card>
      )}
    </div>
  )
}
