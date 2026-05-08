<script setup lang="ts">
// S-01: レシピ一覧画面（画面設計書 4-1）
const { recipes, pending, error, refresh } = useRecipeList()
</script>

<template>
  <div class="min-h-screen bg-gray-50">
    <Header />

    <main class="mx-auto max-w-5xl px-6 py-8">
      <LoadingSkeleton v-if="pending" />
      <ErrorState v-else-if="error" @retry="refresh()" />
      <EmptyState v-else-if="!recipes || recipes.length === 0" />
      <div
        v-else
        class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3"
      >
        <RecipeCard
          v-for="recipe in recipes"
          :key="recipe.id"
          :recipe="recipe"
        />
      </div>
    </main>
  </div>
</template>
