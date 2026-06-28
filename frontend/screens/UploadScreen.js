/
import * as ImagePicker from 'expo-image-picker';
import { getStorage, ref, uploadBytes } from 'firebase/storage';

const pickVideo = async () => {
  const result = await ImagePicker.launchImageLibraryAsync({
    mediaTypes: ImagePicker.MediaTypeOptions.Videos,
    allowsEditing: true,
    quality: 1,
  });
  
  if (!result.canceled) {
    const storageRef = ref(storage, `videos/${userId}/${Date.now()}.mp4`);
    await uploadBytes(storageRef, result.assets[0].uri);
  }
};
