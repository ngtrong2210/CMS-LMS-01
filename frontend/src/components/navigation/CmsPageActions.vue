<template>
  <div class="cms-page-actions">
    <PageBackButton v-if="!route.meta.hideBack" />
    <slot />
  </div>
</template>

<script setup>
import { useRoute } from 'vue-router'
import PageBackButton from './PageBackButton.vue'

const route = useRoute()
</script>

<style scoped src="../../assets/css/components/cms-page-actions.css"></style>
