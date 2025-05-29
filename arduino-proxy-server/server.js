const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();
app.use(cors());
app.use(express.json());

const serviceAccount = require('./firebase-service-account.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "https://mcm-dashboard-97482-default-rtdb.firebaseio.com"
});

const db = admin.database();

app.post('/arduino-data', async (req, res) => {
    try {
        const data = req.body;
        const ref = db.ref("arduinoData");
        const newEntry = ref.push();
        await newEntry.set(data);
        res.status(200).json({ status: 'success', id: newEntry.key });
    } catch (err) {
        console.error("Firebase write error:", err);
        res.status(500).json({ error: 'Failed to write to Firebase' });
    }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`✅ Server running on port ${PORT}`);
});
