## Структура репо (краткая)

```text
RepoRoot

├─► CI & Meta
│   ├─► .github
│   │   └─► workflows
│   │       └─► publish-images.yml
│   └─► .gitignore
│
├─► backend/
│   ├─► Dockerfile
│   ├─► requirements.txt
│   ├─► alembic.ini
│   ├─► alembic
│   │   └─► env.py
│   ├─► output.txt
│   └─► app
│       ├─► __init__.py
│       ├─► main.py
│       ├─► api
│       │   ├─► __init__.py
│       │   └─► v1
│       │       ├─► __init__.py
│       │       ├─► analytics.py
│       │       ├─► attendance.py
│       │       ├─► auth.py
│       │       ├─► courses.py
│       │       ├─► export.py
│       │       ├─► feedback.py
│       │       ├─► lessons.py
│       │       └─► users.py
│       ├─► core
│       │   ├─► __init__.py
│       │   ├─► bigseed.py
│       │   ├─► config.py
│       │   ├─► db.py
│       │   ├─► security.py
│       │   └─► seed.py
│       ├─► models
│       │   ├─► __init__.py
│       │   ├─► attendance.py
│       │   ├─► course.py
│       │   ├─► feedback.py
│       │   ├─► lesson.py
│       │   └─► user.py
│       ├─► schemas
│       │   ├─► __init__.py
│       │   ├─► analytics.py
│       │   ├─► attendance.py
│       │   ├─► auth.py
│       │   │   ├─► course.py
│       │   ├─► feedback.py
│       │   ├─► lesson.py
│       │   └─► user.py
│       └─► services
│           ├─► __init__.py
│           ├─► attendance_service.py
│           ├─► export_service.py
│           └─► feedback_service.py
│
├─► frontend/
│   ├─► .env
│   ├─► .gitignore
│   ├─► Dockerfile
│   ├─► README.md
│   ├─► eslint.config.js
│   ├─► index.html
│   ├─► package.json
│   ├─► package-lock.json
│   ├─► tsconfig.json
│   ├─► tsconfig.app.json
│   ├─► tsconfig.node.json
│   ├─► vite.config.ts
│   ├─► public
│   │   └─► vite.svg
│   └─► src
│       ├─► App.css
│       ├─► App.tsx
│       ├─► index.css
│       ├─► main.tsx
│       ├─► api
│       │   ├─► analytics.ts
│       │   ├─► attendance.ts
│       │   ├─► auth.ts
│       │   ├─► client.ts
│       │   ├─► courses.ts
│       │   ├─► export.ts
│       │   ├─► feedback.ts
│       │   ├─► lessons.ts
│       │   └─► users.ts
│       ├─► assets
│       │   └─► react.svg
│       ├─► components
│       │   └─► layout
│       │       └─► AppLayout.tsx
│       ├─► context
│       │   └─► AuthContext.tsx
│       ├─► pages
│       │   ├─► AnalyticsPage.tsx
│       │   ├─► AttendancePage.tsx
│       │   ├─► CourseCreatePage.tsx
│       │   ├─► CourseDetailPage.tsx
│       │   ├─► CourseEditPage.tsx
│       │   ├─► CoursesPage.tsx
│       │   ├─► ExportPage.tsx
│       │   ├─► FeedbackPage.tsx
│       │   ├─► LoginPage.tsx
│       │   ├─► ProfilePage.tsx
│       │   └─► RegisterPage.tsx
│       └─► router
│           └─► index.tsx
│
├─► imgs/
│   ├─► Analytics
│   │   ├─► ...
│   ├─► Attendance
│   │   ├─► ...
│   ├─► Courses
│   │   ├─► ...
│   ├─► Export
│   │   ├─► ...
│   ├─► Feedback
│   │   ├─► ...
│   ├─► Login
│   │   ├─► ...
│   └─► Profile
│       ├─► ...
