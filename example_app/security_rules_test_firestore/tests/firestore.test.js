import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';

let testEnv;

beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
        projectId: "remote-auth-module",
        firestore: {
            rules: readFileSync("../firestore.rules", "utf8"),
        },
    });
});

beforeEach(async () => {
    await testEnv.clearFirestore();
});

afterAll(async () => {
    await testEnv.cleanup();
});

describe('Users Collection Rules', () => {

    it('can read own document', async () => {
        const db = testEnv.authenticatedContext('alice').firestore();
        const docRef = doc(db, 'users', 'alice');
        await assertSucceeds(getDoc(docRef));
    });

    it('cannot read another users document', async () => {
        const db = testEnv.authenticatedContext('alice').firestore();
        const docRef = doc(db, 'users', 'bob');
        await assertFails(getDoc(docRef));
    });

    it('can create own document with valid data', async () => {
        const db = testEnv.authenticatedContext('alice').firestore();
        const docRef = doc(db, 'users', 'alice');
        await assertSucceeds(setDoc(docRef, {
            uid: 'alice',
            createdAt: testEnv.firestore.FieldValue.serverTimestamp(),
            updatedAt: testEnv.firestore.FieldValue.serverTimestamp()
        }));
    });

    it('cannot create document missing required fields', async () => {
        const db = testEnv.authenticatedContext('alice').firestore();
        const docRef = doc(db, 'users', 'alice');
        await assertFails(setDoc(docRef, {
            uid: 'alice',
            // Missing createdAt, updatedAt
        }));
    });

    it('cannot create document with another users uid', async () => {
        const db = testEnv.authenticatedContext('alice').firestore();
        const docRef = doc(db, 'users', 'alice');
        await assertFails(setDoc(docRef, {
            uid: 'malicious',
            createdAt: testEnv.firestore.FieldValue.serverTimestamp(),
            updatedAt: testEnv.firestore.FieldValue.serverTimestamp()
        }));
    });

    it('can update own document with valid changes', async () => {
        // Setup initial doc using unauthenticated admin context
        await testEnv.withSecurityRulesDisabled(async (context) => {
            const db = context.firestore();
            await setDoc(doc(db, 'users', 'alice'), {
                uid: 'alice',
                createdAt: testEnv.firestore.FieldValue.serverTimestamp(),
                updatedAt: testEnv.firestore.FieldValue.serverTimestamp()
            });
        });

        const db = testEnv.authenticatedContext('alice').firestore();
        const docRef = doc(db, 'users', 'alice');
        await assertSucceeds(updateDoc(docRef, {
            displayName: "Alice Updated",
            updatedAt: testEnv.firestore.FieldValue.serverTimestamp()
        }));
    });

    it('cannot update immutable fields (createdAt)', async () => {
        const now = new Date('2023-01-01');
        await testEnv.withSecurityRulesDisabled(async (context) => {
            const db = context.firestore();
            await setDoc(doc(db, 'users', 'alice'), {
                uid: 'alice',
                createdAt: now,
                updatedAt: now
            });
        });

        const db = testEnv.authenticatedContext('alice').firestore();
        const docRef = doc(db, 'users', 'alice');
        await assertFails(updateDoc(docRef, {
            createdAt: new Date('2024-01-01'), // Try to change createdAt
            updatedAt: testEnv.firestore.FieldValue.serverTimestamp()
        }));
    });

    it('cannot modify uid field on update', async () => {
        await testEnv.withSecurityRulesDisabled(async (context) => {
            const db = context.firestore();
            await setDoc(doc(db, 'users', 'alice'), {
                uid: 'alice',
                createdAt: testEnv.firestore.FieldValue.serverTimestamp(),
                updatedAt: testEnv.firestore.FieldValue.serverTimestamp()
            });
        });

        const db = testEnv.authenticatedContext('alice').firestore();
        const docRef = doc(db, 'users', 'alice');
        await assertFails(updateDoc(docRef, {
            uid: 'hijacked',
            updatedAt: testEnv.firestore.FieldValue.serverTimestamp()
        }));
    });
});
