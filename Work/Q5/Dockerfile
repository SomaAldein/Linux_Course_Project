# שימוש בתמונה רשמית של פייתון
FROM python:3.10-slim

# הגדרת משתנה עבודה בתוך הקונטיינר
WORKDIR /app

# העתקת קבצי הקוד והתלויות
COPY plant_analyzer.py .
COPY requirements.txt .

# התקנת התלויות
RUN pip install --no-cache-dir -r requirements.txt

# יצירת תיקיית פלט לתמונות
RUN mkdir -p /app/output

# הפיכת הסקריפט לקובץ שניתן להריץ
ENTRYPOINT ["python", "plant_analyzer.py"]
