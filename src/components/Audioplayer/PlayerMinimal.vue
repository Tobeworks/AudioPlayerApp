<!-- components/AudioPlayer/PlayerMinimal.vue -->
<template>
    <div class="flex items-center p-3 w-full h-full">
        <img :src="currentTrack.coverImage" class="w-11 h-11 rounded-md object-cover shadow-[0_0_10px_rgba(99,102,241,0.4)]" alt="Album Cover">
        <div class="flex-1 mx-3 whitespace-nowrap overflow-hidden">
            <p class="text-sm font-bold text-white truncate">{{ currentTrack.title }}</p>
            <p class="text-xs text-white/70 truncate">{{ currentTrack.artist }}</p>
        </div>
        <div class="flex items-center mr-8">
            <button @click.stop="$emit('skip-back')" class="text-white mx-1.5">
                <SkipBack size="18" />
            </button>
            <button @click.stop="$emit('toggle-play')" class="bg-indigo-500/70 text-white rounded-full w-9 h-9 flex items-center justify-center mx-2 shadow-[0_0_10px_rgba(129,140,248,0.5)]">
                <Play v-if="!isPlaying" size="20" />
                <Pause v-else size="20" />
            </button>
            <button @click.stop="$emit('skip-forward')" class="text-white mx-1.5">
                <SkipForward size="18" />
            </button>
        </div>
    </div>
</template>

<script setup>
import { Play, Pause, SkipBack, SkipForward } from 'lucide-vue-next';

defineProps({
    currentTrack: {
        type: Object,
        required: true
    },
    isPlaying: {
        type: Boolean,
        default: false
    }
});

defineEmits(['skip-back', 'toggle-play', 'skip-forward']);
</script>