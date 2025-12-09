# generator.py – generazione PDF
# Qui useremo ReportLab. Per ora placeholder.

def create_pdf(report_data, filename="report.pdf"):
    with open(filename, "w") as f:
        f.write("REPORT REPUTATION\n")
        f.write(str(report_data))
