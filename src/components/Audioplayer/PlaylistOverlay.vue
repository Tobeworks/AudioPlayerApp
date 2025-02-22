
<template>
    <!-- Mobile Playlist kommt von unten nach oben -->
    <div v-if="isMobile" class="fixed inset-x-0 bottom-0 z-20 transform transition-transform duration-300" :class="{ 'translate-y-0': show, 'translate-y-full': !show }">
        <div class="bg-gray-900/70 backdrop-blur-md rounded-t-2xl shadow-lg border border-white/10 p-4 max-h-[70vh] overflow-y-auto">
            <div class="sticky top-0 bg-gray-900/90 backdrop-blur-md py-2 z-10">
                <div class="flex justify-between items-center mb-2">
                    <h3 class="text-xl font-bold text-white">Playlist</h3>
                    <button @click.stop="$emit('close')" class="text-gray-400 hover:text-white">
                        <X class="h-6 w-6" />
                    </button>
                </div>
                <!-- Pull indicator -->
                <div class="w-12 h-1 bg-white/30 rounded-full mx-auto mb-4"></div>
            </div>

            <div class="mt-2">
                <ul class="space-y-2">
                    <li v-for="(track, index) in tracks" :key="track.id" @click.stop="$emit('select-track', index)" :class="{ 'bg-indigo-800 bg-opacity-50': currentTrackIndex === index }" class="flex items-center p-3 rounded-md hover:bg-indigo-700/50 cursor-pointer transition-colors">
                        <div class="w-8 h-8 flex items-center justify-center mr-3">
                            <span v-if="currentTrackIndex !== index" class="text-gray-400">{{ index + 1 }}</span>
                            <Play v-else class="text-indigo-400" size="16" />
                        </div>
                        <div class="flex-grow">
                            <p class="font-medium text-white">{{ track.title }}</p>
                            <p class="text-sm text-gray-400">{{ track.artist }}</p>
                        </div>
                    </li>
                </ul>
            </div>
        </div>
    </div>

    <!-- Desktop Playlist als Modal overlay -->
    <div v-else class="absolute inset-0 z-20 flex justify-center items-center bg-black/70 backdrop-blur-md p-4">
        <div class="bg-gray-900/70 backdrop-blur-md rounded-2xl shadow-lg border border-white/10 p-4 w-full max-w-md max-h-[400px] overflow-y-auto">
            <div class="flex justify-between items-center mb-4">
                <h3 class="text-xl font-bold text-white">Playlist</h3>
                <button @click.stop="$emit('close')" class="text-gray-400 hover:text-white">
                    <X class="h-6 w-6" />
                </button>
            </div>
            <ul class="space-y-2">
                <li v-for="(track, index) in tracks" :key="track.id" @click.stop="$emit('select-track', index)" :class="{ 'bg-indigo-800 bg-opacity-50': currentTrackIndex === index }" class="flex items-center p-2 rounded-md hover:bg-indigo-700/50 cursor-pointer transition-colors">
                    <div class="w-8 h-8 flex items-center justify-center mr-3">
                        <span v-if="currentTrackIndex !== index" class="text-gray-400">{{ index + 1 }}</span>
                        <Play v-else class="text-indigo-400" size="16" />
                    </div>
                    <div class="flex-grow">
                        <p class="font-medium text-white">{{ track.title }}</p>
                        <p class="text-sm text-gray-400">{{ track.artist }}</p>
                    </div>
                </li>
            </ul>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { X, Play } from 'lucide-vue-next';

const props = defineProps({
    tracks: {
        type: Array,
        required: true
    },
    currentTrackIndex: {
        type: Number,
        default: 0
    },
    isMobile: {
        type: Boolean,
        default: false
    }
});

defineEmits(['close', 'select-track']);

const show = ref(false);

onMounted(() => {
    // Damit die Animation von unten nach oben läuft
    setTimeout(() => {
        show.value = true;
    }, 10);
});
</script>

<style scoped>
/* Für iOS-ähnliches Scrollverhalten auf mobilen Geräten */
.overflow-y-auto {
    -webkit-overflow-scrolling: touch;
}
</style>