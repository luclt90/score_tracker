# Keep WorkManager and its AndroidX Startup entry point during release shrinking.
#-keep class androidx.work.** { *; }
#-keep class androidx.startup.** { *; }
#-keep class androidx.room.** { *; }
#-keep class androidx.sqlite.** { *; }
#
#-keep class * extends androidx.room.RoomDatabase { *; }
#-keep class * implements androidx.startup.Initializer { *; }


# Chỉ giữ lại constructor không tham số của RoomDatabase (giải quyết vấn đề khởi tạo WorkDatabase)
-keep class * extends androidx.room.RoomDatabase { <init>(); }

# Dự phòng: giữ lại lớp triển khai cụ thể WorkDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# Giữ lại constructor của Worker (nếu bạn sử dụng custom Worker)
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}