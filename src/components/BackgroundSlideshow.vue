<template>
    <div class="background-slideshow">
        <Swiper :modules="swiperModules" :slides-per-view="1" :space-between="0" :loop="true" :effect="'fade'" :fade-effect="{ crossFade: true }" :speed="10000" 
            :autoplay="{ delay: 12000, disableOnInteraction: false }"
            @swiper="onSwiper"
            @slideChange="onSlideChange"
            class="swiper-container"
            >
            <SwiperSlide v-for="(track, index) in tracks" :key="track.id">
                <div class="slide">
                    <img :src="track.coverImage" :alt="track.title" class="slide-image" />
                </div>
            </SwiperSlide>
        </Swiper>
    </div>
</template>

<script setup>
import { ref } from 'vue';
import { Swiper, SwiperSlide } from 'swiper/vue';
import { Autoplay, EffectFade } from 'swiper/modules';
import 'swiper/css';
import 'swiper/css/effect-fade';
import 'swiper/css/autoplay';

// Stellen sicher, dass Module an Swiper übergeben werden
const swiperModules = [Autoplay, EffectFade];

// Tracks data
const tracks = [
    {
        id: 1,
        title: "Image 1",
        coverImage: "https://tracks.logic-moon.de/images/img1.png",
    },
    {
        id: 2,
        title: "Image 2",
        coverImage: "https://tracks.logic-moon.de/images/img2.png",
    },
];

// Swiper Events
const onSwiper = (swiper) => {
    console.log('Swiper initialisiert:', swiper);
};

const onSlideChange = (swiper) => {
    console.log('Slide gewechselt zu:', swiper.activeIndex);
};
</script>

<style scoped>
.background-slideshow {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: -1;
}

.swiper-container {
    width: 100%;
    height: 100%;
}

.slide {
    width: 100%;
    height: 100%;
}

.slide-image {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

/* Verbesserte Fade-Effekt Anpassungen */
:deep(.swiper-slide) {
    transition: opacity 3s cubic-bezier(0.4, 0, 0.2, 1);
}

:deep(.swiper-slide-active) {
    z-index: 1;
}
</style>