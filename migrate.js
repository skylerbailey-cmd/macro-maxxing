const admin = require('./functions/node_modules/firebase-admin');
admin.initializeApp();
const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;
const PRIVATE_KEYS = ['dateOfBirth','currentWeight','goalWeight','heightInches','proteinPerLb','gender','excludeDairy','excludeGluten'];
(async () => {
  const snap = await db.collection('users').get();
  let migrated = 0;
  for (const doc of snap.docs) {
    const data = doc.data();
    const priv = {}, rm = {};
    let found = false;
    for (const k of PRIVATE_KEYS) {
      if (data[k] !== undefined) { priv[k] = data[k]; rm[k] = FieldValue.delete(); found = true; }
    }
    if (found) {
      await doc.ref.collection('private').doc('profile').set(priv, {merge:true});
      await doc.ref.update(rm);
      migrated++;
    }
  }
  console.log('Migrated ' + migrated + ' / ' + snap.size + ' users');
  process.exit(0);
})();
