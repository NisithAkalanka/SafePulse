const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// Cloud Function v2 syntax එකට අනුව
exports.onsosresolve = onDocumentUpdated("alerts/{alertId}", (event) => {
    // දත්ත ලබා ගැනීම (v2 වලදී event.data හරහා ගන්න ඕනේ)
    const newValue = event.data.after.data();
    const previousValue = event.data.before.data();

    // status එක 'resolved' වුණාද කියලා බලනවා
    if (newValue && previousValue && newValue.status === 'resolved' && previousValue.status !== 'resolved') {
        console.log(`✅ [LOG]: Alert ${event.params.alertId} has been RESOLVED by the user.`);
    } else {
        console.log("ℹ️ [LOG]: Something changed in Firestore, but it was not a Resolution.");
    }
});