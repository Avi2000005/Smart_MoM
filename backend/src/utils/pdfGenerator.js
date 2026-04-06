const PDFDocument = require("pdfkit");

function generateMeetingPDF(res, meeting) {
  const doc = new PDFDocument({ margin: 50, size: "A4" });

  res.setHeader("Content-Type", "application/pdf");
  res.setHeader(
    "Content-Disposition",
    `attachment; filename=${meeting.title.replace(/\s+/g, "_")}.pdf`
  );

  doc.pipe(res);

  // Modern corporate color palette
  const primaryBrand = "#2563EB"; // Deep Royal Blue
  const textTitle = "#111827"; // Very dark grey
  const textBody = "#374151"; // Dark grey
  const textMuted = "#6B7280"; // Muted grey
  const headerBg = "#EFF6FF"; // Very light blue
  const lineColor = "#E5E7EB"; // Light border color

  /* ---------- STYLIZED DOCUMENT HEADER ---------- */
  doc.rect(0, 0, doc.page.width, 100).fill(primaryBrand);

  doc
    .fillColor("#FFFFFF")
    .font("Helvetica-Bold")
    .fontSize(24)
    .text("MINUTES OF MEETING", 50, 35, { characterSpacing: 2 });

  doc
    .font("Helvetica")
    .fontSize(10)
    .text("CONFIDENTIAL & PROPRIETARY", 50, 65, { characterSpacing: 1, opacity: 0.8 });

  doc.moveDown(3);

  /* ---------- OVERVIEW SECTION ---------- */
  let y = 135;

  doc
    .font("Helvetica-Bold")
    .fontSize(12)
    .fillColor(textTitle)
    .text("MEETING OVERVIEW", 50, y);

  y += 20;

  // Overview Box
  doc.rect(50, y, doc.page.width - 100, 70).fill(headerBg);
  
  // Left border accent
  doc.rect(48, y, 4, 70).fill(primaryBrand);

  doc
    .fillColor(textTitle)
    .font("Helvetica-Bold")
    .fontSize(12)
    .text(`${meeting.title.toUpperCase()}`, 70, y + 16);

  doc
    .fillColor(textBody)
    .font("Helvetica")
    .fontSize(10)
    .text(`Project: ${meeting.client || "General"}`, 70, y + 40);

  doc
    .fillColor(textBody)
    .font("Helvetica-Bold")
    .fontSize(10)
    .text(
      new Date(meeting.date).toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' }),
      doc.page.width - 250,
      y + 40,
      { width: 180, align: "right" }
    );

  y += 100;

  /* ---------- PARTICIPANTS ---------- */
  if (meeting.participants && meeting.participants.length) {
    doc.fillColor(textTitle).font("Helvetica-Bold").fontSize(12).text("ATTENDEES", 50, y);
    doc.moveTo(50, y + 16).lineTo(doc.page.width - 50, y + 16).strokeColor(lineColor).lineWidth(1).stroke();

    y += 26;

    let colLeft = 50;
    let colRight = 320;
    let currentY = y;

    meeting.participants.forEach((p, i) => {
      let px = i % 2 === 0 ? colLeft : colRight;
      
      doc.circle(px + 4, currentY + 5, 2.5).fill(primaryBrand);
      
      doc
        .fillColor(textBody)
        .font("Helvetica-Bold")
        .fontSize(9)
        .text(`${p.username}`, px + 15, currentY);

      doc
        .fillColor(textMuted)
        .font("Helvetica")
        .fontSize(8.5)
        .text(`${p.email}`, px + 15, currentY + 12);

      if (i % 2 !== 0) {
        currentY += 32;
      }
    });

    if (meeting.participants.length % 2 !== 0) currentY += 32;
    y = currentY + 15;
  }

  /* ---------- ACTION ITEMS / DISCUSSIONS ---------- */
  if (y > doc.page.height - 180) {
    doc.addPage();
    y = 50;
  }

  doc.fillColor(textTitle).font("Helvetica-Bold").fontSize(12).text("ACTION ITEMS & DISCUSSION", 50, y);
  
  y += 24;

  // Table Setup
  // Total width: 500 (50 to 550)
  // Columns: Sr (25) | Category (70) | Topic (145) | Action (120) | Assigned (80) | Deadline (60)
  const colXs = [50, 75, 145, 290, 410, 490];
  const colWidths = [25, 70, 145, 120, 80, 60]; 
  const headers = ["#", "Category", "Topic", "Action", "Assigned", "Deadline"];

  function drawTableRow(yPos, rowData, isHeader) {
    doc.font(isHeader ? "Helvetica-Bold" : "Helvetica").fontSize(isHeader ? 9 : 8.5);
    
    let maxH = 0;
    rowData.forEach((text, i) => {
      const h = doc.heightOfString(text || "-", { width: colWidths[i] - 10 });
      if (h > maxH) maxH = h;
    });

    const rowHeight = maxH + 16; 

    // Background for header
    if (isHeader) {
      doc.rect(50, yPos, doc.page.width - 100, rowHeight).fill(primaryBrand);
      doc.fillColor("#FFFFFF");
    } else {
      doc.fillColor(textBody);
    }

    doc.font(isHeader ? "Helvetica-Bold" : "Helvetica");

    // Alignments
    const alignments = ["center", "left", "left", "left", "left", "center"];

    // Texts
    rowData.forEach((text, i) => {
      doc.text(text || "-", colXs[i] + 5, yPos + 8, {
        width: colWidths[i] - 10,
        align: alignments[i],
      });
    });

    // Elegant bottom line separator for data rows
    if (!isHeader) {
      doc.moveTo(50, yPos + rowHeight).lineTo(doc.page.width - 50, yPos + rowHeight).lineWidth(0.5).strokeColor(lineColor).stroke();
    }

    return rowHeight;
  }

  // Draw Header
  let rowH = drawTableRow(y, headers, true);
  y += rowH;

  // Draw Data
  meeting.tasks.forEach((task, index) => {
    doc.font("Helvetica").fontSize(8.5);
    let previewMaxH = 0;
    
    let formattedDate = "-";
    if (task.deadline) {
      const d = new Date(task.deadline);
      formattedDate = `${d.getDate()}/${d.getMonth()+1}/${d.getFullYear()}`;
    }

    const rowData = [
      (index + 1).toString(),
      task.category || "-",
      task.title || "-",
      task.action || "-",
      task.assignedTo?.username || "-",
      formattedDate,
    ];

    rowData.forEach((text, i) => {
      const h = doc.heightOfString(text || "-", { width: colWidths[i] - 10 });
      if (h > previewMaxH) previewMaxH = h;
    });

    if (y + previewMaxH + 20 > doc.page.height - 50) {
      doc.addPage();
      y = 50;
      rowH = drawTableRow(y, headers, true);
      y += rowH;
    }

    rowH = drawTableRow(y, rowData, false);
    y += rowH;
  });

  /* ---------- FOOTER ---------- */
  const pages = doc.bufferedPageRange ? doc.bufferedPageRange().count : 1;
  doc
    .fontSize(9)
    .font("Helvetica-Oblique")
    .fillColor(textMuted)
    .text(
      "This document was electronically generated by the Smart MoM system and requires no physical signature.",
      50,
      doc.page.height - 50,
      { align: "center", width: doc.page.width - 100 }
    );

  doc.end();
}

module.exports = generateMeetingPDF;