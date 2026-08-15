<template>
  <RouterView />
  <AppConfirmDialog />
</template>

<script setup>
import { RouterView } from 'vue-router'
import AppConfirmDialog from './components/feedback/AppConfirmDialog.vue'
</script>
