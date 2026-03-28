const sgMail = require("@sendgrid/mail");

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

async function sendEmail(to, subject, text) {

  const msg = {
    to: to,
    from: process.env.EMAIL_FROM,
    subject: subject,
    text: text
  };

  await sgMail.send(msg);

}

module.exports = sendEmail;