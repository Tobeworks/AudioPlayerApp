<script setup>
import "./assets/main.css"
import { RouterLink, RouterView } from 'vue-router'
import BackgroundSlideshow from './components/BackgroundSlideshow.vue'; // Hintergrund-Slideshow importieren
</script>

<template>
  <BackgroundSlideshow /> 
  <RouterView />
</template>

<style>

body {
  margin: 0;
  padding: 0;
  overflow: hidden;
}
</style>
