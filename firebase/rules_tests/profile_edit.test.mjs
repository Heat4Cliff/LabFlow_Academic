import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { after, before, test } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc } from 'firebase/firestore';

const rules = readFileSync(resolve('../../firebase/firestore.rules'), 'utf8');
let environment;
let student;
let labAdmin;
let superadmin;

before(async () => {
  environment = await initializeTestEnvironment({
    projectId: 'labflow-profile-rules-test',
    firestore: { rules },
  });
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const firestore = context.firestore();
    for (const [uid, role] of [
      ['student-1', 'student'],
      ['student-2', 'student'],
      ['lab-admin-1', 'lab_admin'],
      ['superadmin-1', 'superadmin'],
    ]) {
      await setDoc(doc(firestore, 'users', uid), {
        uid,
        email: `${uid}@example.invalid`,
        fullName: uid,
        role,
        status: 'active',
      });
    }
    await setDoc(
      doc(firestore, 'lab_memberships', 'lab-admin-1__lab-1'),
      { userId: 'lab-admin-1', labId: 'lab-1', role: 'lab_admin', active: true },
    );
  });
  student = environment.authenticatedContext('student-1').firestore();
  labAdmin = environment.authenticatedContext('lab-admin-1').firestore();
  superadmin = environment.authenticatedContext('superadmin-1').firestore();
});

after(async () => {
  await environment?.cleanup();
});

test('student may change only own fullName', async () => {
  await assertSucceeds(
    updateDoc(doc(student, 'users', 'student-1'), { fullName: 'Nama Baru' }),
  );
  await assertFails(
    updateDoc(doc(student, 'users', 'student-1'), { role: 'lab_admin' }),
  );
  await assertFails(
    updateDoc(doc(student, 'users', 'student-1'), { status: 'active-again' }),
  );
  await assertFails(
    updateDoc(doc(student, 'users', 'student-1'), { uid: 'someone-else' }),
  );
  await assertFails(
    updateDoc(doc(student, 'users', 'student-1'), { fullName: '   ' }),
  );
  await assertFails(
    updateDoc(doc(student, 'users', 'student-2'), { fullName: 'Hijacked' }),
  );
});

test('lab admin may change own name but cannot edit membership', async () => {
  await assertSucceeds(
    updateDoc(doc(labAdmin, 'users', 'lab-admin-1'), {
      fullName: 'Admin Lab Baru',
    }),
  );
  await assertFails(
    updateDoc(doc(labAdmin, 'lab_memberships', 'lab-admin-1__lab-1'), {
      active: false,
    }),
  );
});

test('superadmin retains administrative update permission', async () => {
  await assertSucceeds(
    updateDoc(doc(superadmin, 'users', 'student-2'), {
      fullName: 'Diperbarui Admin',
    }),
  );
  assert.ok(environment);
});
