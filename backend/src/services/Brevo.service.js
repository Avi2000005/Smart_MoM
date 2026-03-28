// services/brevo.service.js

const axios = require("axios");

async function sendVerificationOTP(toEmail, toName, otp) {
  try {
    const response = await axios.post(
      "https://api.brevo.com/v3/smtp/email",
      {
        sender: {
          name: process.env.BREVO_SENDER_NAME || "Smart MoM",
          email: process.env.BREVO_SENDER_EMAIL,
        },
        to: [
          {
            email: toEmail,
            name: toName,
          },
        ],
        subject: "Your Smart MoM Verification Code",
        htmlContent: `
          <h2>Hello ${toName}</h2>
          <p>Your OTP is:</p>
          <h1>${otp}</h1>
          <p>This expires in 10 minutes</p>
        `,
      },
      {
        headers: {
          "api-key": process.env.BREVO_API_KEY,
          "Content-Type": "application/json",
        },
      }
    );

    console.log("✅ Email sent:", response.data);
    return true;

  } catch (error) {
    console.error(
      "❌ Brevo Error:",
      error.response?.data || error.message
    );
    return false;
  }
}

module.exports = { sendVerificationOTP };