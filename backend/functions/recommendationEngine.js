
const getRecommendedVideos = async (userId) => {
  // 1. جلب سجل مشاهدات المستخدم
  const userViews = await db.collection('views')
    .where('userId', '==', userId)
    .orderBy('timestamp', 'desc')
    .limit(50)
    .get();

  // 2. تحليل الاهتمامات (الهاشتاقات المشاهدة)
  const interests = {};
  userViews.forEach(doc => {
    const tags = doc.data().videoTags;
    tags.forEach(tag => interests[tag] = (interests[tag] || 0) + 1);
  });

  // 3. جلب فيديوهات مشابهة
  const recommended = await db.collection('videos')
    .where('tags', 'array-contains-any', Object.keys(interests))
    .orderBy('createdAt', 'desc')
    .limit(20)
    .get();

  return recommended.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
