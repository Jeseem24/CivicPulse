require("dotenv").config();
const { GoogleGenerativeAI } = require("@google/generative-ai");

async function testEmbed() {
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const models = ["text-embedding-004", "models/text-embedding-004", "embedding-001", "models/embedding-001"];
  
  for (const m of models) {
    try {
      const model = genAI.getGenerativeModel({ model: m });
      const res = await model.embedContent("Dangerous pothole near school entrance");
      console.log(`✅ Embedding SUCCESS with model "${m}": vector length = ${res.embedding.values.length}`);
      return m;
    } catch (err) {
      console.log(`❌ Embedding FAILED with model "${m}":`, err.message);
    }
  }
}

testEmbed();
