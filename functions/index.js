const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();

exports.cdnProxy = functions
  .region("asia-northeast3")
  .https.onRequest(async (req, res) => {
    try {
      let filePath = req.path.replace("/storage-api/", "");
      filePath = decodeURIComponent(filePath);

      const bucket = admin.storage().bucket("more_pick");
      const file = bucket.file(filePath);

      const [exists] = await file.exists();
      if (!exists) {
        res.status(404).send("Image not found");
        return;
      }

      // 🔥 CDN 핵심: 강력한 캐시 헤더 부여
      res.set("Cache-Control", "public, max-age=31536000, s-maxage=31536000, immutable");

      const readStream = file.createReadStream();
      readStream.pipe(res);
    } catch (error) {
      console.error(error);
      res.status(500).send("Internal Server Error");
    }
  });