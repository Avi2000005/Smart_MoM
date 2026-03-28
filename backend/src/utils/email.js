// utils/email.js
// Uses Brevo REST API via Axios — no SDK needed
// npm install axios
 
const axios = require("axios");
 
/**
 * Send a transactional email via Brevo REST API
 * @param {string} to      - Recipient email
 * @param {string} subject - Email subject
 * @param {string} text    - Plain text body
 */
async function sendEmail(to, subject, text) {
 
  const htmlContent = `
    <!DOCTYPE html>
    <html>
      <body style="font-family: Arial, sans-serif; background: #f4f4f9; padding: 32px;">
        <div style="max-width: 480px; margin: auto; background: #fff;
                    border-radius: 12px; padding: 32px;
                    box-shadow: 0 4px 16px rgba(0,0,0,0.08);">
          <div style="text-align:center; margin-bottom: 20px;">
            <div style="display:inline-block; background: linear-gradient(135deg,#7C3AED,#A78BFA);
                        border-radius:12px; padding:12px 16px;">
              <span style="font-size:26px;">📋</span>
            </div>
          </div>
          <h2 style="color:#1a1a2e; text-align:center; margin:0 0 16px;">${subject}</h2>
          <p style="color:#374151; line-height:1.6; margin:0 0 24px;">${text}</p>
          <hr style="border:none; border-top:1px solid #e5e7eb; margin:0 0 16px;" />
          <p style="color:#d1d5db; font-size:11px; text-align:center; margin:0;">
            © Smart MoM — Minutes of Meeting App
          </p>
        </div>
      </body>
    </html>
  `;
 
  try {
 
    await axios.post(
      "https://api.brevo.com/v3/smtp/email",
      {
        sender: {
          name:  process.env.BREVO_SENDER_NAME  || "Smart MoM",
          email: process.env.BREVO_SENDER_EMAIL
        },
        to: [{ email: to }],
        subject:      subject,
        textContent:  text,
        htmlContent:  htmlContent
      },
      {
        headers: {
          "api-key":     process.env.BREVO_API_KEY,
          "Content-Type": "application/json"
        }
      }
    );
 
    console.log(`✅ Email sent to ${to}`);
 
  } catch (error) {
    console.error(
      "❌ Brevo email error:",
      error.response?.data || error.message
    );
    throw error;
  }
 
}
 
module.exports = sendEmail;