<template>
    <div class="background-slideshow">
        <div v-if="isLoading" class="loading-overlay">
            <div class="loading-spinner"></div>
        </div>

        <Swiper v-if="images.length > 0" :modules="swiperModules" :slides-per-view="1" :space-between="0" :loop="true" :effect="'fade'" :fade-effect="{ crossFade: true }" :speed="10000" :autoplay="{ delay: 12000, disableOnInteraction: false }" @swiper="onSwiper" @slideChange="onSlideChange" class="swiper-container">
            <SwiperSlide v-for="(image, index) in images" :key="image.id">
                <div class="slide">
                    <img :src="image.coverImage" :alt="image.title" class="slide-image" />
                </div>
            </SwiperSlide>
        </Swiper>

        <!-- Fallback wenn keine Bilder geladen werden konnten -->
        <div v-else-if="!isLoading && error" class="error-message">
            <p>{{ error }}</p>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { Swiper, SwiperSlide } from 'swiper/vue';
import { Autoplay, EffectFade } from 'swiper/modules';
import axios from 'axios';
import 'swiper/css';
import 'swiper/css/effect-fade';
import 'swiper/css/autoplay';

// Stellen sicher, dass Module an Swiper übergeben werden
const swiperModules = [Autoplay, EffectFade];

// Zustandsvariablen
const images = ref([]);
const isLoading = ref(true);
const error = ref(null);

// API-URL - kann für Produktionsumgebung angepasst werden
const apiUrl = import.meta.env.DEV
    ? 'http://localhost:5000/tobeworks/audioplayer_images'
    : 'https://twapi1-nr2qe7lb3q-oa.a.run.app/tobeworks/audioplayer_images';

// Bilder von der API laden
const fetchImages = async () => {
    isLoading.value = true;
    error.value = null;

    try {
        const response = await axios.get(apiUrl);

        // Prüfen, ob die Antwort erfolgreich ist und Daten enthält
        if (response.data && response.data.status === 1 && response.data.data) {
            images.value = response.data.data;
            console.log('Geladene Bilder:', images.value);
        } else {
            error.value = 'Keine Bilder verfügbar';
            console.error('API-Antwort hat keine gültigen Daten:', response);
        }
    } catch (err) {
        error.value = 'Fehler beim Laden der Bilder';
        console.error('Fehler beim Abrufen der Bilder:', err);

        // Fallback zu Test-Daten im Fehlerfall
        images.value = [
            {
                id: 1,
                title: "Fallback Image 1",
                coverImage: "https://tracks.logic-moon.de/images/img1.png",
            },
            {
                id: 2,
                title: "Fallback Image 2",
                coverImage: "https://tracks.logic-moon.de/images/img2.png",
            }
        ];
    } finally {
        isLoading.value = false;
    }
};

// Swiper Events
const onSwiper = (swiper) => {
    console.log('Swiper initialisiert:', swiper);
};

const onSlideChange = (swiper) => {
    console.log('Slide gewechselt zu:', swiper.activeIndex);
};

// Beim Mounten der Komponente Bilder laden
onMounted(() => {
    fetchImages();
});
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

/* Lade-Indikator */
.loading-overlay {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: rgba(0, 0, 0, 0.5);
    z-index: 2;
}

.loading-spinner {
    width: 50px;
    height: 50px;
    border: 3px solid rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    border-top-color: #fff;
    animation: spin 1s ease-in-out infinite;
}

.error-message {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
    color: #fff;
    background-color: rgba(0, 0, 0, 0.7);
    text-align: center;
    padding: 2rem;
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}
</style>