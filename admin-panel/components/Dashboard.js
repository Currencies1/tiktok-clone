
import React, { useEffect, useState } from 'react';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '../firebaseConfig';

export default function Dashboard() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    totalVideos: 0,
    reports: 0
  });

  useEffect(() => {
    const fetchStats = async () => {
      const usersSnap = await getDocs(collection(db, 'users'));
      const videosSnap = await getDocs(collection(db, 'videos'));
      const reportsSnap = await getDocs(collection(db, 'reports'));
      
      setStats({
        totalUsers: usersSnap.size,
        totalVideos: videosSnap.size,
        reports: reportsSnap.size
      });
    };
    fetchStats();
  }, []);

  return (
    <div className="dashboard">
      <h1>لوحة تحكم المشرف</h1>
      <div className="stats-grid">
        <div className="stat-card">👥 {stats.totalUsers} مستخدم</div>
        <div className="stat-card">🎥 {stats.totalVideos} فيديو</div>
        <div className="stat-card">⚠️ {stats.reports} بلاغ</div>
      </div>
    </div>
  );
}
