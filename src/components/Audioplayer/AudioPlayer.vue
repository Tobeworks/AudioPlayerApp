<template>
    <div ref="playerRef" class="fixed z-50 select-none" :style="{ left: playerPosition.x + 'px', top: playerPosition.y + 'px', maxWidth: '480px' }" @mousedown="startDrag">
        <div class="relative backdrop-blur-md bg-gray-900/60 rounded-2xl shadow-lg border border-white/10 overflow-hidden transition-all duration-500 ease-in-out" :class="{ 'w-96 h-[70px]': isCollapsed, 'w-[480px]': !isCollapsed }">

            <!-- Collapse toggle - gleiche Position für beide Zustände -->
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

            <!-- Playlist Overlay -->
            <div v-if="isPlaylistOpen" class="absolute inset-0 z-20 flex justify-center items-center bg-black/70 backdrop-blur-md p-4">
                <div class="bg-gray-900/70 backdrop-blur-md rounded-2xl shadow-lg border border-white/10 p-4 w-full max-w-md max-h-[400px] overflow-y-auto">
                    <div class="flex justify-between items-center mb-4">
                        <h3 class="text-xl font-bold text-white">Playlist</h3>
                        <button @click.stop="togglePlaylist" class="text-gray-400 hover:text-white">
                            <X class="h-6 w-6" />
                        </button>
                    </div>
                    <ul class="space-y-2">
                        <li v-for="(track, index) in tracks" :key="track.id" @click.stop="selectTrack(index)" :class="{ 'bg-indigo-800 bg-opacity-50': currentTrackIndex === index }" class="flex items-center p-2 rounded-md hover:bg-indigo-700/50 cursor-pointer transition-colors">
                            <div class="w-8 h-8 flex items-center justify-center mr-3">
                                <span v-if="currentTrackIndex !== index" class="text-gray-400">{{ index + 1 }}</span>
                                <Play v-else size="16" class="text-indigo-400" />
                            </div>
                            <div class="flex-grow">
                                <p class="font-medium text-white">{{ track.title }}</p>
                                <p class="text-sm text-gray-400">{{ track.artist }}</p>
                            </div>
                        </li>
                    </ul>
                </div>
            </div>

            <!-- Main Player UI - Only visible when not collapsed -->
            <div v-if="!isCollapsed && !error && !(isLoading && tracks.length === 0)" class="p-6">
                <div class="flex items-center justify-between mb-4">
                    <button @click.stop="togglePlaylist" class="text-white hover:text-indigo-300 transition-colors p-2 rounded-full hover:bg-white/10">
                        <Menu class="w-5 h-5" />
                    </button>
                    <h2 class="text-xl font-bold text-white">Logic Moon</h2>
                    <div class="w-9 h-9"><!-- Spacer für symmetrisches Layout --></div>
                </div>

                <div class="flex justify-center mb-6">
                    <div class="relative w-48 h-48 rounded-lg overflow-hidden shadow-[0_0_20px_rgba(99,102,241,0.4)]">
                        <img :src="currentTrack.coverImage" alt="Album Cover" class="w-full h-full object-cover">
                        <div v-if="isLoading" class="absolute inset-0 flex items-center justify-center bg-black/50">
                            <div class="w-8 h-8 border-3 border-white/30 border-t-white rounded-full animate-spin"></div>
                        </div>
                    </div>
                </div>

                <div class="mb-4 text-center">
                    <h3 class="text-lg font-bold text-white">{{ currentTrack.title }}</h3>
                    <p class="text-sm text-indigo-300">{{ currentTrack.artist }}</p>
                </div>

                <!-- Progress bar -->
                <div class="relative h-2 bg-white/20 rounded-full mb-2 cursor-pointer" @click.stop="seekAudio">
                    <div class="absolute top-0 left-0 h-full bg-indigo-500 rounded-full" :style="{ width: progressPercentage + '%' }"></div>
                </div>

                <!-- Time display -->
                <div class="flex justify-between text-sm text-gray-300 mb-4">
                    <span>{{ formatTime(currentTime) }}</span>
                    <span>{{ formatTime(duration) }}</span>
                </div>

                <!-- Controls -->
                <div class="flex justify-center items-center mb-6">
                    <button @click.stop="toggleShuffle" :class="{ 'text-indigo-400': isShuffleEnabled, 'text-gray-300': !isShuffleEnabled }" class="hover:text-white mx-3 transition-colors">
                        <Shuffle size="20" />
                    </button>

                    <button @click.stop="skipBack" class="text-white hover:text-indigo-300 mx-3 transition-colors">
                        <SkipBack size="24" />
                    </button>

                    <button @click.stop="togglePlay" class="bg-indigo-500/70 hover:bg-indigo-500/90 text-white rounded-full w-14 h-14 flex items-center justify-center mx-3 shadow-[0_0_15px_rgba(129,140,248,0.5)] transition-transform hover:scale-105">
                        <Play v-if="!isPlaying" size="24" />
                        <Pause v-else size="24" />
                    </button>

                    <button @click.stop="skipForward" class="text-white hover:text-indigo-300 mx-3 transition-colors">
                        <SkipForward size="24" />
                    </button>

                    <button @click.stop="toggleRepeat" :class="{ 'text-indigo-400': isRepeatEnabled, 'text-gray-300': !isRepeatEnabled }" class="hover:text-white mx-3 transition-colors">
                        <Repeat size="20" />
                    </button>
                </div>

                <!-- Volume control -->
                <div class="flex items-center px-4">
                    <Volume2 class="text-gray-300 mr-2" size="16" />
                    <input type="range" min="0" max="1" step="0.01" v-model="volume" @input="updateVolume" @click.stop class="w-full h-1 rounded-lg bg-white/20 appearance-none cursor-pointer focus:outline-none [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-indigo-500" />
                </div>
            </div>

            <!-- Minimal Player UI - Only visible when collapsed -->
            <div v-else-if="!error && !(isLoading && tracks.length === 0)" class="flex items-center p-3 w-full h-full">
                <img :src="currentTrack.coverImage" class="w-11 h-11 rounded-md object-cover shadow-[0_0_10px_rgba(99,102,241,0.4)]" alt="Album Cover">
                <div class="flex-1 mx-3 whitespace-nowrap overflow-hidden">
                    <p class="text-sm font-bold text-white truncate">{{ currentTrack.title }}</p>
                    <p class="text-xs text-white/70 truncate">{{ currentTrack.artist }}</p>
                </div>
                <div class="flex items-center mr-8">
                    <button @click.stop="skipBack" class="text-white mx-1.5">
                        <SkipBack size="18" />
                    </button>
                    <button @click.stop="togglePlay" class="bg-indigo-500/70 text-white rounded-full w-9 h-9 flex items-center justify-center mx-2 shadow-[0_0_10px_rgba(129,140,248,0.5)]">
                        <Play v-if="!isPlaying" size="20" />
                        <Pause v-else size="20" />
                    </button>
                    <button @click.stop="skipForward" class="text-white mx-1.5">
                        <SkipForward size="18" />
                    </button>
                </div>
            </div>
        </div>

        <!-- Hidden audio element -->
        <audio ref="audioElement" preload="metadata" @timeupdate="onTimeUpdate" @loadedmetadata="onLoadedMetadata" @ended="onEnded" @error="onError"></audio>
    </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { Play, Pause, SkipBack, SkipForward, Volume2, Shuffle, Repeat, ChevronDown, ChevronUp, Move, X, List, Menu } from 'lucide-vue-next';
import axios from 'axios';

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
            playerPosition.value = state.position || { x: 20, y: 20 };
            currentTrackIndex.value = state.currentTrackIndex || 0;
            isShuffleEnabled.value = state.isShuffleEnabled || false;
            isRepeatEnabled.value = state.isRepeatEnabled || false;
        }
    } catch (error) {
        console.error('Fehler beim Laden des Player-Status:', error);
    }
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

const onEnded = () => {
    isPlaying.value = false;

    if (isRepeatEnabled.value) {
        // Wenn Repeat aktiviert ist, den aktuellen Track wiederholen
        audioElement.value.currentTime = 0;
        audioElement.value.play().catch(error => {
            console.error("Fehler beim Wiederholen:", error);
        });
        isPlaying.value = true;
    } else {
        // Automatisch zum nächsten Track springen
        const nextIndex = (currentTrackIndex.value + 1) % tracks.value.length;
        loadTrack(nextIndex);

        // Nach kurzem Delay abspielen, um dem Audio-Element Zeit zu geben
        setTimeout(() => {
            audioElement.value.play().catch(error => {
                console.error("Fehler beim Abspielen des nächsten Tracks:", error);
            });
            isPlaying.value = true;
        }, 100);
    }
};


const loadTrack = async (index) => {
    if (index < 0 || index >= tracks.value.length) return;

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

const updateVolume = () => {
    audioElement.value.volume = volume.value;
    savePlayerState();
};

const toggleCollapse = () => {
    isCollapsed.value = !isCollapsed.value;
    savePlayerState();
};

const startDrag = (event) => {
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

watch(volume, () => {
    savePlayerState();
});
</script>

<style scoped>
/* Minimale CSS-Stile, die nicht gut mit Tailwind umsetzbar sind */
.border-t-white {
    border-top-color: white;
}
</style>