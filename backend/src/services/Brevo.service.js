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

async function sendPasswordResetOTP(toEmail, toName, otp) {
  try {
    const response = await axios.post(
      "https://api.brevo.com/v3/smtp/email",
      {
         sender: {
          name: process.env.BREVO_SENDER_NAME || "Smart MoM",
          email: process.env.BREVO_SENDER_EMAIL,
        },
        to: [{ email: toEmail, name: toName }],
        subject: "Your Smart MoM Password Reset OTP",
        htmlContent: `
          <div style="font-family:sans-serif;max-width:400px;margin:auto;
                      padding:24px;border-radius:12px;background:#1a1a2e;
                      color:#fff;text-align:center">
            <h2 style="color:#a855f7">Smart MoM</h2>
            <p>Hi <b>${toName}</b>, you requested a password reset.</p>
            <p>Use the OTP below to reset your password:</p>
            <div style="font-size:36px;font-weight:bold;letter-spacing:12px;
                        color:#a855f7;margin:24px 0">${otp}</div>
            <p style="color:#aaa;font-size:13px">Expires in <b>10 minutes</b>.</p>
            <p style="color:#aaa;font-size:12px">If you didn't request this, ignore this email.</p>
          </div>
        `,
      },
       {
        headers: {
          "api-key": process.env.BREVO_API_KEY,
          "Content-Type": "application/json",
        },
      }
    );

    console.log("✅ Password reset OTP sent:", response.data);
    return true;

  } catch (error) {
    console.error("❌ Brevo sendPasswordResetOTP Error:",
      error.response?.data || error.message);
    return false;
  }
}


module.exports = { sendVerificationOTP, sendPasswordResetOTP };