<!-- components/AudioPlayer/AudioPlayer.vue (Hauptkomponente) -->
<template>
    <div ref="playerRef" class="fixed z-50 select-none" :class="{ 'w-full top-0 left-0': isMobile, 'cursor-grab active:cursor-grabbing': isDragging }" :style="isMobile ? {} : { left: playerPosition.x + 'px', top: playerPosition.y + 'px', maxWidth: '480px' }" @mousedown="startDrag">

        <div class="relative backdrop-blur-md bg-gray-900/60 rounded-lg md:rounded-2xl shadow-lg border border-white/10 overflow-hidden transition-all duration-500 ease-in-out" :class="{
            'w-full h-[70px] rounded-b-none': isMobile && isCollapsed,
            'w-full h-auto': isMobile && !isCollapsed,
            'w-96 h-[70px]': !isMobile && isCollapsed,
            'w-[480px]': !isMobile && !isCollapsed
        }">

            <!-- Collapse toggle button -->
            <div class="absolute top-5 right-3 cursor-pointer z-10 p-2 rounded-full bg-white/10 flex items-center justify-center hover:bg-white/20" @click.stop="toggleCollapse">
                <ChevronDown v-if="!isCollapsed" size="12" class="text-white" />
                <ChevronUp v-else size="12" class="text-white" />
            </div>

            <!-- Error Message -->
            <div v-if="error" class="flex flex-col items-center justify-center py-8 px-6 text-center min-h-[200px]">
                <p class="text-red-400 mb-4">{{ error }}</p>
                <button @click.stop="fetchTracks" class="bg-indigo-500/70 hover:bg-indigo-500/90 text-white rounded-lg px-4 py-2 text-sm transition-colors">
                    Erneut versuchen
                </button>
            </div>

            <!-- Global Loading State -->
            <div v-if="isLoading && tracks.length === 0" class="flex flex-col items-center justify-center py-8 px-6 min-h-[200px]">
                <div class="w-8 h-8 border-3 border-white/30 border-t-white rounded-full animate-spin"></div>
                <p class="mt-4 text-white text-center">Tracks werden geladen...</p>
            </div>

            <!-- Main Player UI - Only visible when not collapsed -->
            <template v-if="!isCollapsed && !error && !(isLoading && tracks.length === 0)">
                <PlayerExpanded :current-track="currentTrack" :is-loading="isLoading" :current-time="currentTime" :duration="duration" :progress-percentage="progressPercentage" :is-playing="isPlaying" :is-shuffle-enabled="isShuffleEnabled" :is-repeat-enabled="isRepeatEnabled" :volume="volume" @toggle-playlist="togglePlaylist" @seek-audio="seekAudio" @toggle-shuffle="toggleShuffle"
                    @skip-back="skipBack" @toggle-play="togglePlay" @skip-forward="skipForward" @toggle-repeat="toggleRepeat" @update-volume="updateVolume" />
            </template>

            <!-- Minimal Player UI - Only visible when collapsed -->
            <template v-else-if="!error && !(isLoading && tracks.length === 0)">
                <PlayerMinimal :current-track="currentTrack" :is-playing="isPlaying" @skip-back="skipBack" @toggle-play="togglePlay" @skip-forward="skipForward" />
            </template>
        </div>

        <!-- Playlist Overlay - Position based on mobile or desktop -->
        <PlaylistOverlay v-if="isPlaylistOpen" :tracks="tracks" :current-track-index="currentTrackIndex" :is-mobile="isMobile" @close="togglePlaylist" @select-track="selectTrack" />

        <!-- Hidden audio element -->
        <audio ref="audioElement" preload="metadata" @timeupdate="onTimeUpdate" @loadedmetadata="onLoadedMetadata" @ended="onEnded" @error="onError"></audio>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, onUnmounted } from 'vue';
import { ChevronDown, ChevronUp } from 'lucide-vue-next';
import axios from 'axios';

// Import child components
import PlayerExpanded from './PlayerExpanded.vue';
import PlayerMinimal from './PlayerMinimal.vue';
import PlaylistOverlay from './PlaylistOverlay.vue';

// State
const audioElement = ref(null);
const isPlaying = ref(false);
const currentTime = ref(0);
const duration = ref(0);
const volume = ref(0.7);
const currentTrackIndex = ref(0);
const isShuffleEnabled = ref(false);
const isRepeatEnabled = ref(false);
const isPlaylistOpen = ref(false);
const isLoading = ref(true);
const isCollapsed = ref(true); // Standardmäßig eingeklappt
const playerPosition = ref({ x: 20, y: 20 });
const isDragging = ref(false);
const dragOffset = ref({ x: 0, y: 0 });
const error = ref(null);
const playerRef = ref(null);
const isMobile = ref(false);

// Tracks data
const tracks = ref([]);

// API URL basierend auf Umgebung
const apiUrl = import.meta.env.DEV
    ? 'http://localhost:5000/tobeworks/audioplayer_tracks'
    : 'https://twapi1-nr2qe7lb3q-oa.a.run.app/tobeworks/audioplayer_tracks';

// Computed properties
const currentTrack = computed(() => {
    return tracks.value.length > 0 && currentTrackIndex.value < tracks.value.length
        ? tracks.value[currentTrackIndex.value]
        : { title: 'Kein Track geladen', artist: 'Unbekannt', coverImage: '' };
});

const progressPercentage = computed(() => {
    return duration.value ? (currentTime.value / duration.value) * 100 : 0;
});

// LocalStorage Funktionen
const savePlayerState = () => {
    const state = {
        volume: volume.value,
        isCollapsed: isCollapsed.value,
        position: playerPosition.value,
        currentTrackIndex: currentTrackIndex.value,
        isShuffleEnabled: isShuffleEnabled.value,
        isRepeatEnabled: isRepeatEnabled.value
    };
    localStorage.setItem('audioPlayerState', JSON.stringify(state));
};

const loadPlayerState = () => {
    try {
        const savedState = localStorage.getItem('audioPlayerState');
        if (savedState) {
            const state = JSON.parse(savedState);
            volume.value = state.volume || 0.7;
            isCollapsed.value = state.isCollapsed !== undefined ? state.isCollapsed : true;

            // Nur Position laden, wenn nicht im Mobile-Modus
            if (!isMobile.value) {
                playerPosition.value = state.position || { x: 20, y: 20 };
            }

            currentTrackIndex.value = state.currentTrackIndex || 0;
            isShuffleEnabled.value = state.isShuffleEnabled || false;
            isRepeatEnabled.value = state.isRepeatEnabled || false;
        }
    } catch (error) {
        console.error('Fehler beim Laden des Player-Status:', error);
    }
};

// Check if on mobile
const checkMobile = () => {
    isMobile.value = window.innerWidth < 768; // md breakpoint in Tailwind
};

// Tracks von der API laden
const fetchTracks = async () => {
    isLoading.value = true;
    error.value = null;

    try {
        const response = await axios.get(apiUrl);

        if (response.data && response.data.status === 1 && response.data.data) {
            tracks.value = response.data.data;
            console.log('Geladene Tracks:', tracks.value);

            // Nach erfolgreichem Laden den ersten Track initialisieren
            if (tracks.value.length > 0) {
                await loadTrack(currentTrackIndex.value);
            }
        } else {
            error.value = 'Keine Tracks verfügbar';
            console.error('API-Antwort enthält keine gültigen Daten:', response);
            isLoading.value = false;
        }
    } catch (err) {
        error.value = 'Fehler beim Laden der Tracks';
        console.error('Fehler beim Abrufen der Tracks:', err);
        isLoading.value = false;
    }
};

// Methods
const togglePlay = () => {
    if (isPlaying.value) {
        audioElement.value.pause();
    } else {
        isLoading.value = true;
        audioElement.value.play().catch(error => {
            console.error("Fehler beim Abspielen:", error);
            isLoading.value = false;
        });
    }
    isPlaying.value = !isPlaying.value;
};

const loadTrack = async (index) => {
    if (index < 0 || index >= tracks.value.length) return;

    // Log for debugging
    console.log(`Lade Track ${index + 1}/${tracks.value.length}: ${tracks.value[index].title}`);

    currentTrackIndex.value = index;
    currentTime.value = 0;
    duration.value = 0;
    isPlaying.value = false;
    isLoading.value = true;

    // Reset audio element
    if (audioElement.value) {
        audioElement.value.pause();
        audioElement.value.currentTime = 0;
        audioElement.value.src = tracks.value[index].url;
    }

    // Preload the audio
    try {
        await audioElement.value.load();
        savePlayerState(); // Speichere den aktuellen Track
    } catch (error) {
        console.error("Fehler beim Laden des Tracks:", error);
        isLoading.value = false;
    }
};

const skipForward = () => {
    if (tracks.value.length === 0) return;

    if (isShuffleEnabled.value) {
        playRandomTrack();
    } else {
        const nextIndex = (currentTrackIndex.value + 1) % tracks.value.length;
        loadTrack(nextIndex);
        if (isPlaying.value) {
            setTimeout(() => {
                audioElement.value.play().catch(error => {
                    console.error("Fehler beim Abspielen nach Skip:", error);
                });
            }, 100);
        }
    }
};

const skipBack = () => {
    if (tracks.value.length === 0) return;

    // If we're more than 3 seconds into the song, go back to the start
    if (currentTime.value > 3) {
        audioElement.value.currentTime = 0;
        return;
    }

    if (isShuffleEnabled.value) {
        playRandomTrack();
    } else {
        const prevIndex = (currentTrackIndex.value - 1 + tracks.value.length) % tracks.value.length;
        loadTrack(prevIndex);
        if (isPlaying.value) {
            setTimeout(() => {
                audioElement.value.play().catch(error => {
                    console.error("Fehler beim Abspielen nach Skip:", error);
                });
            }, 100);
        }
    }
};

const playRandomTrack = () => {
    if (tracks.value.length === 0) return;

    const randomIndex = Math.floor(Math.random() * tracks.value.length);
    loadTrack(randomIndex);
    if (isPlaying.value) {
        setTimeout(() => {
            audioElement.value.play().catch(error => {
                console.error("Fehler beim Abspielen nach Shuffle:", error);
            });
        }, 100);
    }
};

const toggleShuffle = () => {
    isShuffleEnabled.value = !isShuffleEnabled.value;
    savePlayerState();
};

const toggleRepeat = () => {
    isRepeatEnabled.value = !isRepeatEnabled.value;
    savePlayerState();
};

const togglePlaylist = () => {
    isPlaylistOpen.value = !isPlaylistOpen.value;
};

const selectTrack = (index) => {
    loadTrack(index);
    isPlaylistOpen.value = false;
    setTimeout(() => {
        audioElement.value.play().catch(error => {
            console.error("Fehler beim Abspielen nach Auswahl:", error);
        });
        isPlaying.value = true;
    }, 100);
};

const onTimeUpdate = () => {
    currentTime.value = audioElement.value.currentTime;
    isLoading.value = false;
};

const onLoadedMetadata = () => {
    duration.value = audioElement.value.duration;
    isLoading.value = false;
};

const onEnded = () => {
    // Wir wissen, dass ein Track gerade zu Ende gespielt wurde
    // Also sollte der nächste auch automatisch spielen

    if (isRepeatEnabled.value) {
        audioElement.value.currentTime = 0;
        audioElement.value.play().catch(error => {
            console.error("Fehler beim Wiederholen:", error);
        });
        isPlaying.value = true;
    } else {
        // Zum nächsten Track und automatisch abspielen
        const nextIndex = (currentTrackIndex.value + 1) % tracks.value.length;
        loadTrack(nextIndex);

        setTimeout(() => {
            audioElement.value.play().catch(error => {
                console.error("Fehler beim Abspielen des nächsten Tracks:", error);
            });
            isPlaying.value = true;
        }, 100);
    }
};

const onError = (e) => {
    console.error("Audio-Fehler:", e);
    isPlaying.value = false;
    isLoading.value = false;
};

const formatTime = (seconds) => {
    if (isNaN(seconds) || seconds === Infinity) return "0:00";

    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
};

const seekAudio = (event) => {
    const rect = event.target.getBoundingClientRect();
    const seekPosition = (event.clientX - rect.left) / rect.width;
    audioElement.value.currentTime = duration.value * seekPosition;
};

const updateVolume = (newVolume) => {
    volume.value = newVolume;
    audioElement.value.volume = volume.value;
    savePlayerState();
};

const toggleCollapse = () => {
    isCollapsed.value = !isCollapsed.value;
    savePlayerState();
};

// Dragging functionality - nur für Desktop
const startDrag = (event) => {
    // Nicht draggable auf Mobile
    if (isMobile.value) return;

    // Ignoriere Drag auf interaktiven Elementen
    if (event.target.closest('button') || event.target.closest('input')) {
        return;
    }

    isDragging.value = true;
    const containerRect = playerRef.value.getBoundingClientRect();
    dragOffset.value = {
        x: event.clientX - containerRect.left,
        y: event.clientY - containerRect.top
    };

    // Add event listeners for drag and end drag
    document.addEventListener('mousemove', onDrag);
    document.addEventListener('mouseup', endDrag);
};

const onDrag = (event) => {
    if (isDragging.value) {
        playerPosition.value = {
            x: Math.max(0, Math.min(window.innerWidth - 300, event.clientX - dragOffset.value.x)),
            y: Math.max(0, Math.min(window.innerHeight - 70, event.clientY - dragOffset.value.y))
        };
    }
};

const endDrag = () => {
    if (isDragging.value) {
        isDragging.value = false;
        document.removeEventListener('mousemove', onDrag);
        document.removeEventListener('mouseup', endDrag);
        savePlayerState(); // Speichere die Position
    }
};

// Lifecycle hooks
onMounted(() => {
    // Check mobile
    checkMobile();
    window.addEventListener('resize', checkMobile);

    // Lade gespeicherten Zustand
    loadPlayerState();

    if (audioElement.value) {
        audioElement.value.volume = volume.value;
    }

    // Tracks von der API laden
    fetchTracks();

    // Event-Listener für Auto-Speichern
    window.addEventListener('beforeunload', savePlayerState);
});

// Aufräumen
onUnmounted(() => {
    window.removeEventListener('resize', checkMobile);
    window.removeEventListener('beforeunload', savePlayerState);

    if (isDragging.value) {
        document.removeEventListener('mousemove', onDrag);
        document.removeEventListener('mouseup', endDrag);
    }
});

// Export formatTime für andere Komponenten
defineExpose({ formatTime });
</script>

<style scoped>
.border-t-white {
    border-top-color: white;
}

/* Setze die spezifischen Mauszeiger-Stile */
.cursor-grab {
    cursor: grab;
}

.active\:cursor-grabbing:active {
    cursor: grabbing;
}
</style>