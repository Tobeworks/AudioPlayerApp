<!-- components/AudioPlayer.vue -->
<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { Play, Pause, SkipBack, SkipForward, Volume2, Shuffle, Repeat, ChevronDown, ChevronUp, Move } from 'lucide-vue-next';

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
const showVisualizer = ref(false);
const analyser = ref(null);
const audioContext = ref(null);
const audioSource = ref(null);
const canvasContext = ref(null);
const isLoading = ref(false);
const isCollapsed = ref(false);
const playerPosition = ref({ x: 20, y: 20 });
const isDragging = ref(false);
const dragOffset = ref({ x: 0, y: 0 });

// Tracks data
const tracks = [
    {
        id: 1,
        title: "01 - Outland",
        artist: "Logic Moon",
        url: "https://tracks.logic-moon.de/audio/01_outland.m4a",
        coverImage: "https://tracks.logic-moon.de/covers/Music for Film Cover.jpg"
    },
    {
        id: 2,
        title: "02 - New Arcadia",
        artist: "Logic Moon",
        url: "https://tracks.logic-moon.de/audio/02_new%20arcadia.m4a",
        coverImage: "https://tracks.logic-moon.de/covers/Music for Film Cover.jpg"
    },
    {
        id: 4,
        title: "03 - Settlers",
        artist: "Logic Moon",
        url: "https://tracks.logic-moon.de/audio/03_settlers02.m4a",
        coverImage: "https://tracks.logic-moon.de/covers/Music for Film Cover.jpg"
    },
    {
        id: 5,
        title: "04 - Metropolis",
        artist: "Logic Moon",
        url: "https://tracks.logic-moon.de/audio/04_metropolis.m4a",
        coverImage: "https://tracks.logic-moon.de/covers/Music for Film Cover.jpg"
    },
    {
        id: 6,
        title: "05 - Horizon",
        artist: "Logic Moon",
        url: "https://tracks.logic-moon.de/audio/05_horizon.m4a",
        coverImage: "https://tracks.logic-moon.de/covers/Music for Film Cover.jpg"
    },
    {
        id: 8,
        title: "06 - Meld",
        artist: "Logic Moon",
        url: "https://tracks.logic-moon.de/audio/06_meld_02.m4a",
        coverImage: "https://tracks.logic-moon.de/covers/Music for Film Cover.jpg"
    },
    {
        id: 10,
        title: "07 - Tranquility",
        artist: "Logic Moon",
        url: "https://tracks.logic-moon.de/audio/07_tranqility_02.m4a",
        coverImage: "https://tracks.logic-moon.de/covers/Music for Film Cover.jpg"
    },
    {
        id: 12,
        title: "08 - Artifacts",
        artist: "Logic Moon",
        url: "https://tracks.logic-moon.de/audio/08_artifacts_02.m4a",
        coverImage: "https://tracks.logic-moon.de/covers/Music for Film Cover.jpg"
    },
    {
        id: 13,
        title: "Thw Wanderers",
        artist: "Logic Moon",
        url: "https://tracks.logic-moon.de/audio/track_01.m4a",
        coverImage: "https://tracks.logic-moon.de/covers/Music for Film Cover.jpg"
    }
];

// Computed properties
const currentTrack = computed(() => tracks[currentTrackIndex.value]);
const progressPercentage = computed(() => {
    return duration.value ? (currentTime.value / duration.value) * 100 : 0;
});

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
    if (index < 0 || index >= tracks.length) return;

    currentTrackIndex.value = index;
    currentTime.value = 0;
    duration.value = 0;
    isPlaying.value = false;
    isLoading.value = true;

    if (audioSource.value) {
        audioSource.value.disconnect();
        audioSource.value = null;
    }

    // Reset audio element
    if (audioElement.value) {
        audioElement.value.pause();
        audioElement.value.currentTime = 0;
        audioElement.value.src = currentTrack.value.url;
    }

    // Preload the audio
    try {
        await audioElement.value.load();
    } catch (error) {
        console.error("Fehler beim Laden des Tracks:", error);
        isLoading.value = false;
    }
};

const initAudioVisualizer = () => {
    if (!audioContext.value) {
        audioContext.value = new (window.AudioContext || window.webkitAudioContext)();
        analyser.value = audioContext.value.createAnalyser();
        analyser.value.fftSize = 256;
    }

    if (audioSource.value) {
        audioSource.value.disconnect();
    }

    audioSource.value = audioContext.value.createMediaElementSource(audioElement.value);
    audioSource.value.connect(analyser.value);
    analyser.value.connect(audioContext.value.destination);

    const canvas = document.getElementById('visualizer');
    if (canvas) {
        canvasContext.value = canvas.getContext('2d');
        renderVisualizer();
    }
};

const renderVisualizer = () => {
    if (!showVisualizer.value || !analyser.value || !canvasContext.value) return;

    const canvas = canvasContext.value.canvas;
    const WIDTH = canvas.width;
    const HEIGHT = canvas.height;

    const bufferLength = analyser.value.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);
    analyser.value.getByteFrequencyData(dataArray);

    canvasContext.value.clearRect(0, 0, WIDTH, HEIGHT);

    const barWidth = (WIDTH / bufferLength) * 2.5;
    let x = 0;

    for (let i = 0; i < bufferLength; i++) {
        const barHeight = dataArray[i] / 2;

        // Gradient from blue to purple based on frequency
        const r = 50 + (i / bufferLength) * 205;
        const g = 50;
        const b = 200;

        canvasContext.value.fillStyle = `rgb(${r}, ${g}, ${b})`;
        canvasContext.value.fillRect(x, HEIGHT - barHeight, barWidth, barHeight);

        x += barWidth + 1;
    }

    requestAnimationFrame(renderVisualizer);
};

const toggleVisualizer = () => {
    showVisualizer.value = !showVisualizer.value;
    if (showVisualizer.value && audioElement.value) {
        if (!audioContext.value) {
            initAudioVisualizer();
        } else {
            renderVisualizer();
        }
    }
};

const skipForward = () => {
    if (isShuffleEnabled.value) {
        playRandomTrack();
    } else {
        const nextIndex = (currentTrackIndex.value + 1) % tracks.length;
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
    // If we're more than 3 seconds into the song, go back to the start
    if (currentTime.value > 3) {
        audioElement.value.currentTime = 0;
        return;
    }

    if (isShuffleEnabled.value) {
        playRandomTrack();
    } else {
        const prevIndex = (currentTrackIndex.value - 1 + tracks.length) % tracks.length;
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
    const randomIndex = Math.floor(Math.random() * tracks.length);
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
};

const toggleRepeat = () => {
    isRepeatEnabled.value = !isRepeatEnabled.value;
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
    isPlaying.value = false;

    if (isRepeatEnabled.value) {
        audioElement.value.currentTime = 0;
        audioElement.value.play().catch(error => {
            console.error("Fehler beim Wiederholen:", error);
        });
        isPlaying.value = true;
    } else {
        skipForward(); // Automatisch zum nächsten Track
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

const updateVolume = () => {
    audioElement.value.volume = volume.value;
};

const toggleCollapse = () => {
    isCollapsed.value = !isCollapsed.value;
};

// Dragging functionality
const startDrag = (event) => {
    isDragging.value = true;
    const containerRect = event.currentTarget.getBoundingClientRect();
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
            x: event.clientX - dragOffset.value.x,
            y: event.clientY - dragOffset.value.y
        };
    }
};

const endDrag = () => {
    isDragging.value = false;
    document.removeEventListener('mousemove', onDrag);
    document.removeEventListener('mouseup', endDrag);
};

// Lifecycle hooks
onMounted(() => {
    if (audioElement.value) {
        audioElement.value.volume = volume.value;
        // Automatisches Laden des ersten Tracks beim Start
        loadTrack(0);
    }
});
</script>

<template>
    <div class="audio-player-container" :style="{ left: playerPosition.x + 'px', top: playerPosition.y + 'px' }">
        <div class="glass-audio-player" :class="{ 'collapsed': isCollapsed }">
            <!-- Drag handle -->
            <div class="drag-handle" @mousedown="startDrag">
                <Move size="16" class="text-white opacity-70" />
            </div>

            <!-- Collapse toggle -->
            <div class="collapse-toggle" @click="toggleCollapse">
                <ChevronDown v-if="!isCollapsed" size="20" class="text-white" />
                <ChevronUp v-else size="20" class="text-white" />
            </div>

            <!-- Playlist Overlay -->
            <div v-if="isPlaylistOpen" class="playlist-overlay">
                <div class="playlist-container glass-panel">
                    <div class="flex justify-between items-center mb-4">
                        <h3 class="text-xl font-bold text-white">Playlist</h3>
                        <button @click="togglePlaylist" class="text-gray-400 hover:text-white">
                            <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        </button>
                    </div>
                    <ul class="space-y-2">
                        <li v-for="(track, index) in tracks" :key="track.id" @click="selectTrack(index)" :class="{ 'bg-indigo-800 bg-opacity-50': currentTrackIndex === index }" class="flex items-center p-2 rounded-md hover:bg-indigo-700 hover:bg-opacity-50 cursor-pointer transition-colors">
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
            <div v-if="!isCollapsed" class="player-content">
                <div class="flex items-center justify-between mb-4">
                    <button @click="togglePlaylist" class="text-white hover:text-indigo-300 transition">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h7" />
                        </svg>
                    </button>
                    <h2 class="text-xl font-bold text-white">Logic Moon</h2>
                     <button @click="toggleVisualizer" class="text-white hover:text-indigo-300 transition">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                        </svg>
                    </button> 
                </div>

                <div class="flex justify-center mb-6">
                    <div class="relative w-48 h-48 rounded-lg overflow-hidden shadow-glow">
                        <img :src="currentTrack.coverImage" alt="Album Cover" class="w-full h-full object-cover">
                        <div v-if="isLoading" class="absolute inset-0 flex items-center justify-center bg-black bg-opacity-50">
                            <div class="loading-spinner"></div>
                        </div>
                    </div>
                </div>

                <div class="mb-4 text-center">
                    <h3 class="text-lg font-bold text-white">{{ currentTrack.title }}</h3>
                    <p class="text-sm text-indigo-300">{{ currentTrack.artist }}</p>
                </div>

                <!-- Visualizer -->
                <canvas v-if="showVisualizer" id="visualizer" class="w-full h-24 rounded-md mb-4"></canvas>

                <!-- Progress bar -->
                <div class="relative h-2 bg-white bg-opacity-20 rounded-full mb-2 cursor-pointer" @click="seekAudio">
                    <div class="absolute top-0 left-0 h-full bg-indigo-500 rounded-full" :style="{ width: progressPercentage + '%' }"></div>
                </div>

                <!-- Time display -->
                <div class="flex justify-between text-sm text-gray-300 mb-4">
                    <span>{{ formatTime(currentTime) }}</span>
                    <span>{{ formatTime(duration) }}</span>
                </div>

                <!-- Controls -->
                <div class="flex justify-center items-center mb-6">
                    <button @click="toggleShuffle" :class="{ 'text-indigo-400': isShuffleEnabled }" class="text-gray-300 hover:text-white mx-3 transition">
                        <Shuffle size="20" />
                    </button>

                    <button @click="skipBack" class="text-white hover:text-indigo-300 mx-3 transition">
                        <SkipBack size="24" />
                    </button>

                    <button @click="togglePlay" class="play-button">
                        <Play v-if="!isPlaying" size="24" />
                        <Pause v-else size="24" />
                    </button>

                    <button @click="skipForward" class="text-white hover:text-indigo-300 mx-3 transition">
                        <SkipForward size="24" />
                    </button>

                    <button @click="toggleRepeat" :class="{ 'text-indigo-400': isRepeatEnabled }" class="text-gray-300 hover:text-white mx-3 transition">
                        <Repeat size="20" />
                    </button>
                </div>

                <!-- Volume control -->
                <div class="flex items-center px-4">
                    <Volume2 class="text-gray-300 mr-2" size="16" />
                    <input type="range" min="0" max="1" step="0.01" v-model="volume" @input="updateVolume" class="w-full">
                </div>
            </div>

            <!-- Minimal Player UI - Only visible when collapsed -->
            <div v-else class="mini-player">
                <img :src="currentTrack.coverImage" class="mini-cover" alt="Album Cover">
                <div class="mini-info">
                    <p class="mini-title">{{ currentTrack.title }}</p>
                    <p class="mini-artist">{{ currentTrack.artist }}</p>
                </div>
                <div class="mini-controls">
                    <button @click="skipBack" class="mini-button">
                        <SkipBack size="18" />
                    </button>
                    <button @click="togglePlay" class="mini-play-button">
                        <Play v-if="!isPlaying" size="20" />
                        <Pause v-else size="20" />
                    </button>
                    <button @click="skipForward" class="mini-button">
                        <SkipForward size="18" />
                    </button>
                </div>
            </div>
        </div>

        <!-- Hidden audio element -->
        <audio ref="audioElement" preload="metadata" @timeupdate="onTimeUpdate" @loadedmetadata="onLoadedMetadata" @ended="onEnded" @error="onError"></audio>
    </div>
</template>

<style scoped>
.audio-player-container {
    position: fixed;
    z-index: 1000;
    max-width: 480px;
    /* Starting position is set by JavaScript */
}

.glass-audio-player {
    position: relative;
    backdrop-filter: blur(16px);
    background: rgba(23, 25, 35, 0.6);
    border-radius: 16px;
    box-shadow: 0 4px 30px rgba(0, 0, 0, 0.2);
    border: 1px solid rgba(255, 255, 255, 0.1);
    overflow: hidden;
    transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1);
    max-width: 100%;
    width: 480px;
}

.glass-audio-player.collapsed {
    width: 300px;
    height: 70px;
}

.player-content {
    padding: 24px;
}

.drag-handle {
    position: absolute;
    top: 10px;
    left: 10px;
    cursor: move;
    z-index: 10;
    padding: 8px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
}

.collapse-toggle {
    position: absolute;
    top: 10px;
    right: 10px;
    cursor: pointer;
    z-index: 10;
    padding: 8px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.1);
    display: flex;
    align-items: center;
    justify-content: center;
}

.shadow-glow {
    box-shadow: 0 0 20px rgba(99, 102, 241, 0.4);
}

.playlist-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    z-index: 20;
    display: flex;
    justify-content: center;
    align-items: center;
    background-color: rgba(0, 0, 0, 0.7);
    backdrop-filter: blur(16px);
    padding: 1rem;
}

.glass-panel {
    background: rgba(30, 30, 46, 0.7);
    backdrop-filter: blur(16px);
    border-radius: 16px;
    box-shadow: 0 4px 30px rgba(0, 0, 0, 0.2);
    border: 1px solid rgba(255, 255, 255, 0.1);
    padding: 16px;
    width: 100%;
    max-width: 400px;
    max-height: 400px;
    overflow-y: auto;
}

.loading-spinner {
    width: 30px;
    height: 30px;
    border: 3px solid rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    border-top-color: #fff;
    animation: spin 1s ease-in-out infinite;
}

.play-button {
    background: rgba(129, 140, 248, 0.7);
    color: white;
    border-radius: 50%;
    width: 56px;
    height: 56px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 12px;
    box-shadow: 0 0 15px rgba(129, 140, 248, 0.5);
    transition: all 0.3s;
}

.play-button:hover {
    background: rgba(129, 140, 248, 0.9);
    transform: scale(1.05);
}

/* Mini player styles */
.mini-player {
    display: flex;
    align-items: center;
    padding: 12px 24px;
    width: 100%;
    height: 100%;
}

.mini-cover {
    width: 45px;
    height: 45px;
    border-radius: 6px;
    object-fit: cover;
    box-shadow: 0 0 10px rgba(99, 102, 241, 0.4);
}

.mini-info {
    flex: 1;
    margin: 0 12px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

.mini-title {
    font-size: 14px;
    font-weight: bold;
    color: white;
    margin: 0;
    padding: 0;
}

.mini-artist {
    font-size: 12px;
    color: rgba(255, 255, 255, 0.7);
    margin: 0;
    padding: 0;
}

.mini-controls {
    display: flex;
    align-items: center;
}

.mini-button {
    color: white;
    margin: 0 6px;
}

.mini-play-button {
    background: rgba(129, 140, 248, 0.7);
    color: white;
    border-radius: 50%;
    width: 36px;
    height: 36px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 8px;
    box-shadow: 0 0 10px rgba(129, 140, 248, 0.5);
}

input[type=range] {
    -webkit-appearance: none;
    appearance: none;
    height: 5px;
    border-radius: 5px;
    background: rgba(255, 255, 255, 0.2);
    outline: none;
}

input[type=range]::-webkit-slider-thumb {
    -webkit-appearance: none;
    appearance: none;
    width: 12px;
    height: 12px;
    border-radius: 50%;
    background: #818cf8;
    cursor: pointer;
    box-shadow: 0 0 5px rgba(129, 140, 248, 0.7);
}

@keyframes spin {
    to {
        transform: rotate(360deg);
    }
}




</style>