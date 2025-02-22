<!-- components/AudioPlayer/PlayerExpanded.vue -->
<template>
    <div class="p-6">
        <!-- Header mit Player Titel -->
        <div class="flex items-center justify-between mb-4">
            <button @click.stop="$emit('toggle-playlist')" class="text-white hover:text-indigo-300 transition-colors p-2 rounded-full hover:bg-white/10">
                <Menu class="w-5 h-5" />
            </button>
            <h2 class="text-xl font-bold text-white">Logic Moon</h2>
            <div class="w-9 h-9"><!-- Spacer für symmetrisches Layout --></div>
        </div>

        <!-- Cover Art -->
        <div class="flex justify-center mb-6">
            <div class="relative w-48 h-48 rounded-lg overflow-hidden shadow-[0_0_20px_rgba(99,102,241,0.4)]">
                <img :src="currentTrack.coverImage" alt="Album Cover" class="w-full h-full object-cover">
                <div v-if="isLoading" class="absolute inset-0 flex items-center justify-center bg-black/50">
                    <div class="w-8 h-8 border-3 border-white/30 border-t-white rounded-full animate-spin"></div>
                </div>
            </div>
        </div>

        <!-- Track Info -->
        <div class="mb-4 text-center">
            <h3 class="text-lg font-bold text-white">{{ currentTrack.title }}</h3>
            <p class="text-sm text-indigo-300">{{ currentTrack.artist }}</p>
        </div>

        <!-- Progress bar -->
        <div class="relative h-2 bg-white/20 rounded-full mb-2 cursor-pointer" @click.stop="$emit('seek-audio', $event)">
            <div class="absolute top-0 left-0 h-full bg-indigo-500 rounded-full" :style="{ width: progressPercentage + '%' }"></div>
        </div>

        <!-- Time display -->
        <div class="flex justify-between text-sm text-gray-300 mb-4">
            <span>{{ formatTime(currentTime) }}</span>
            <span>{{ formatTime(duration) }}</span>
        </div>

        <!-- Controls -->
        <div class="flex justify-center items-center mb-6">
            <button @click.stop="$emit('toggle-shuffle')" :class="{ 'text-indigo-400': isShuffleEnabled, 'text-gray-300': !isShuffleEnabled }" class="hover:text-white mx-3 transition-colors">
                <Shuffle size="20" />
            </button>

            <button @click.stop="$emit('skip-back')" class="text-white hover:text-indigo-300 mx-3 transition-colors">
                <SkipBack size="24" />
            </button>

            <button @click.stop="$emit('toggle-play')" class="bg-indigo-500/70 hover:bg-indigo-500/90 text-white rounded-full w-14 h-14 flex items-center justify-center mx-3 shadow-[0_0_15px_rgba(129,140,248,0.5)] transition-transform hover:scale-105">
                <Play v-if="!isPlaying" size="24" />
                <Pause v-else size="24" />
            </button>

            <button @click.stop="$emit('skip-forward')" class="text-white hover:text-indigo-300 mx-3 transition-colors">
                <SkipForward size="24" />
            </button>

            <button @click.stop="$emit('toggle-repeat')" :class="{ 'text-indigo-400': isRepeatEnabled, 'text-gray-300': !isRepeatEnabled }" class="hover:text-white mx-3 transition-colors">
                <Repeat size="20" />
            </button>
        </div>

        <!-- Volume control -->
        <div class="flex items-center px-4">
            <Volume2 class="text-gray-300 mr-2" size="16" />
            <input type="range" min="0" max="1" step="0.01" v-model="localVolume" @input="updateVolume" @click.stop class="w-full h-1 rounded-lg bg-white/20 appearance-none cursor-pointer focus:outline-none [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-indigo-500" />
        </div>
    </div>
</template>

<script setup>
import { ref, watch, inject } from 'vue';
import { Play, Pause, SkipBack, SkipForward, Volume2, Shuffle, Repeat, Menu } from 'lucide-vue-next';

const props = defineProps({
    currentTrack: {
        type: Object,
        required: true
    },
    isLoading: {
        type: Boolean,
        default: false
    },
    currentTime: {
        type: Number,
        default: 0
    },
    duration: {
        type: Number,
        default: 0
    },
    progressPercentage: {
        type: Number,
        default: 0
    },
    isPlaying: {
        type: Boolean,
        default: false
    },
    isShuffleEnabled: {
        type: Boolean,
        default: false
    },
    isRepeatEnabled: {
        type: Boolean,
        default: false
    },
    volume: {
        type: Number,
        default: 0.7
    }
});

const emit = defineEmits([
    'toggle-playlist',
    'seek-audio',
    'toggle-shuffle',
    'skip-back',
    'toggle-play',
    'skip-forward',
    'toggle-repeat',
    'update-volume'
]);

// Lokale Kopie von Volume für das Slider-Element
const localVolume = ref(props.volume);

// Aktualisiere localVolume wenn sich props.volume ändert
watch(() => props.volume, (newValue) => {
    localVolume.value = newValue;
});

// Zeit-Formatter
const formatTime = (seconds) => {
    if (isNaN(seconds) || seconds === Infinity) return "0:00";

    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
};

// Volume-Update nach oben emittieren
const updateVolume = () => {
    emit('update-volume', localVolume.value);
};
</script>

<style scoped>
.border-t-white {
    border-top-color: white;
}
</style>