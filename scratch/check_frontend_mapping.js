const BASE_URL = 'http://localhost:8081';

async function main() {
  try {
    const [apiUsers, apiStudents, apiEnrollments] = await Promise.all([
      fetch(`${BASE_URL}/api/users`).then(r => r.json()),
      fetch(`${BASE_URL}/api/students`).then(r => r.json()),
      fetch(`${BASE_URL}/api/enrollments`).then(r => r.json()),
    ]);

    const studentPkByUserId = new Map();
    apiStudents.forEach(s => {
      if (s.userId && s.studentId) {
        studentPkByUserId.set(s.userId.toLowerCase(), s.studentId.toLowerCase());
      }
    });

    const classIdByStudentPk = new Map();
    apiEnrollments.forEach(e => {
      if (e.studentId && e.classId && e.status === 'ACTIVE') {
        classIdByStudentPk.set(e.studentId.toLowerCase(), e.classId);
      }
    });

    const studentsByClass = new Map();
    
    // Simulate user mapping
    apiUsers.forEach(u => {
      const role = u.roleId === 3 ? 'student' : u.roleId === 2 ? 'teacher' : u.roleId === 4 ? 'parent' : 'admin';
      if (role === 'student' && u.userId) {
        const studentPk = studentPkByUserId.get(u.userId.toLowerCase());
        let classId = undefined;
        if (studentPk) {
          classId = classIdByStudentPk.get(studentPk);
        }
        
        const email = u.email || `${u.username || u.userId}@estudiez.edu.vn`;
        
        console.log(`Student: ${u.fullName} (${email}), userId: ${u.userId}, studentPk: ${studentPk}, classId: ${classId}`);

        if (classId !== undefined) {
          const classStr = String(classId);
          if (!studentsByClass.has(classStr)) {
            studentsByClass.set(classStr, []);
          }
          studentsByClass.get(classStr).push({ fullName: u.fullName, email });
        }
      }
    });

    console.log('\n--- Rosters by Class ---');
    for (const [classId, list] of studentsByClass.entries()) {
      console.log(`Class ID ${classId} (${list.length} students):`);
      list.forEach((s, i) => console.log(`  ${i+1}. ${s.fullName} (${s.email})`));
    }
  } catch (err) {
    console.error(err);
  }
}

main();
