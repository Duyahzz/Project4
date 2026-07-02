import docx

doc = docx.Document("eStudiez_Design_Document.docx")
print("Searching in paragraphs...")
for idx, para in enumerate(doc.paragraphs):
    txt = para.text.strip()
    if any(keyword in txt.lower() for keyword in ["architecture", "figure", "sơ đồ", "luồng", "flow", "jwt", "firebase", "thymeleaf", "spring"]):
        print(f"P{idx}: {txt[:300]}")
