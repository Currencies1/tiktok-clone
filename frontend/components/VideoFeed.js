
import React, { useState, useRef } from 'react';
import { View, FlatList, Dimensions } from 'react-native';
import { Video } from 'expo-av';

const { height } = Dimensions.get('window');

export default function VideoFeed({ videos }) {
  const [activeIndex, setActiveIndex] = useState(0);
  
  const renderItem = ({ item, index }) => (
    <View style={{ height, justifyContent: 'center' }}>
      <Video
        source={{ uri: item.videoUrl }}
        style={{ width: '100%', height: '100%' }}
        resizeMode="cover"
        isLooping
        shouldPlay={index === activeIndex}
      />
      {/* أزرار التفاعل */}
    </View>
  );

  return (
    <FlatList
      data={videos}
      renderItem={renderItem}
      pagingEnabled
      vertical
      onScroll={(e) => {
        const index = Math.round(e.nativeEvent.contentOffset.y / height);
        setActiveIndex(index);
      }}
    />
  );
}
