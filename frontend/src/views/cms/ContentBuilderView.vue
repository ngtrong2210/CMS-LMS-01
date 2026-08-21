<template>
  <section>
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div>
        <span class="builder-eyebrow">SOẠN MÔN HỌC LỚP</span>
        <h1 class="page-title">{{ course.title }}</h1>
        <p class="page-subtitle mb-0">Tổ chức chương, bài học, học liệu và bài tập cho đúng lớp trong năm học.</p>
      </div>
      <CmsPageActions>
        <RouterLink class="btn btn-action-view" to="/cms/videos"
          ><i class="bi bi-collection-play"></i> Thư viện video</RouterLink
        ><button class="btn btn-action-create" @click="openChapter()"><i class="bi bi-plus-lg"></i> Thêm chương</button>
      </CmsPageActions>
    </header>
    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      {{ message }}
    </div>
    <div v-if="loading" class="app-card p-5 text-center"><span class="spinner-border text-success"></span></div>
    <template v-else>
      <div v-if="chapters.length" class="chapter-display-toolbar app-card">
        <div>
          <i class="bi bi-layout-text-sidebar-reverse"></i>
          <span
            ><strong>{{ chapters.length }} chương</strong
            ><small>Chọn chương cần soạn để giảm chiều dài danh sách.</small></span
          >
        </div>
        <div class="chapter-display-actions">
          <button type="button" class="btn btn-action-view btn-sm" @click="expandAllChapters">
            <i class="bi bi-arrows-expand"></i> Mở tất cả
          </button>
          <button type="button" class="btn btn-action-cancel btn-sm" @click="collapseAllChapters">
            <i class="bi bi-arrows-collapse"></i> Thu gọn tất cả
          </button>
        </div>
      </div>
      <div class="builder">
        <article
          v-for="(chapter, index) in chapters"
          :key="chapter.id"
          :class="['app-card', 'chapter-card', { 'is-collapsed': isChapterCollapsed(chapter.id) }]"
        >
          <header>
            <span class="number">{{ index + 1 }}</span>
            <div class="chapter-copy">
              <strong>{{ chapter.title }}</strong
              ><small
                >{{ chapter.lessons.length }} bài học •
                {{ chapter.status === 'ACTIVE' ? 'Hoạt động' : 'Tạm ẩn' }}</small
              >
            </div>
            <div class="chapter-header-actions ms-auto">
              <button
                type="button"
                class="chapter-toggle"
                :title="isChapterCollapsed(chapter.id) ? 'Mở nội dung chương' : 'Thu gọn chương'"
                :aria-label="isChapterCollapsed(chapter.id) ? `Mở ${chapter.title}` : `Thu gọn ${chapter.title}`"
                :aria-expanded="!isChapterCollapsed(chapter.id)"
                @click="toggleChapter(chapter.id)"
              >
                <i :class="['bi', isChapterCollapsed(chapter.id) ? 'bi-chevron-down' : 'bi-chevron-up']"></i>
              </button>
              <button
                class="btn btn-action-create btn-sm chapter-add-button"
                title="Thêm bài học"
                @click="openLesson(chapter)"
              >
                <i class="bi bi-plus-lg"></i><span>Thêm bài học</span>
              </button>
              <button class="btn btn-action-edit btn-sm" title="Sửa chương" @click="openChapter(chapter)">
                <i class="bi bi-pencil"></i></button
              ><button
                class="btn btn-action-delete btn-action-outline btn-sm"
                title="Xóa chương"
                @click="askDelete('chapter', chapter)"
              >
                <i class="bi bi-trash"></i>
              </button>
            </div>
          </header>
          <div v-show="!isChapterCollapsed(chapter.id)" class="chapter-lessons">
            <div v-for="lesson in chapter.lessons" :key="lesson.id" class="lesson">
              <span :class="['type', lessonTypeClass(lesson.lessonType)]"
                ><i :class="['bi', lessonTypeIcon(lesson.lessonType)]"></i
              ></span>
              <div class="lesson-copy">
                <strong>{{ lesson.title }}</strong
                ><small
                  >{{ lessonTypeLabel(lesson.lessonType) }} • {{ formatTime(lesson.durationSeconds)
                  }}<template v-if="lesson.videoTitle"> • {{ lesson.videoTitle }}</template></small
                >
              </div>
              <span :class="['badge', lesson.status === 'ACTIVE' ? 'badge-soft-success' : 'badge-soft-warning']">{{
                lesson.status === 'ACTIVE' ? 'Hoạt động' : 'Tạm ẩn'
              }}</span>
              <div class="lesson-actions">
                <RouterLink
                  v-if="lesson.videoId && lesson.canEditVideo"
                  class="btn btn-action-view btn-sm"
                  :to="`/cms/videos/${lesson.videoId}/editor`"
                  title="Biên tập video mẫu"
                  ><i class="bi bi-sliders"></i></RouterLink
                ><button
                  v-if="lesson.lessonType.includes('VIDEO')"
                  class="btn btn-blue btn-sm"
                  :title="lesson.videoId ? 'Đổi video tham chiếu' : 'Chọn video từ thư viện'"
                  @click="openVideoPicker(lesson)"
                >
                  <i class="bi bi-collection-play"></i></button
                ><button class="btn btn-action-edit btn-sm" title="Sửa bài học" @click="openLesson(chapter, lesson)">
                  <i class="bi bi-pencil"></i></button
                ><button
                  class="btn btn-action-delete btn-action-outline btn-sm"
                  title="Xóa bài học"
                  @click="askDelete('lesson', lesson)"
                >
                  <i class="bi bi-trash"></i>
                </button>
              </div>
            </div>
            <div v-if="!chapter.lessons.length" class="empty-lessons">Chương này chưa có bài học.</div>
            <button class="add-lesson" @click="openLesson(chapter)">
              <i class="bi bi-plus-circle"></i> Thêm bài học
            </button>
          </div>
        </article>
        <div v-if="!chapters.length" class="app-card empty-state">
          <i class="bi bi-journal-plus"></i>
          <h2>Chưa có chương</h2>
          <p>Tạo chương đầu tiên để bắt đầu xây dựng nội dung môn học lớp.</p>
          <button class="btn btn-action-create" @click="openChapter()">
            <i class="bi bi-plus-lg"></i> Thêm chương
          </button>
        </div>
      </div>
    </template>

    <div v-if="chapterModal" class="modal-mask" @click.self="chapterModal = false">
      <form class="app-card form-modal" @submit.prevent="saveChapter">
        <div class="modal-heading">
          <div>
            <small>Chương môn học</small>
            <h2>{{ chapterForm.id ? 'Sửa chương' : 'Thêm chương' }}</h2>
          </div>
          <button type="button" class="btn-close" @click="chapterModal = false"></button>
        </div>
        <div class="row g-3">
          <div class="col-12">
            <label class="form-label">Tên chương</label
            ><input v-model.trim="chapterForm.title" class="form-control" required maxlength="500" />
          </div>
          <div class="col-12">
            <label class="form-label">Mô tả</label
            ><textarea v-model.trim="chapterForm.description" class="form-control" rows="3"></textarea>
          </div>
          <div class="col-md-6">
            <label class="form-label">Thứ tự</label
            ><input v-model.number="chapterForm.sortOrder" class="form-control" type="number" min="1" required />
          </div>
          <div class="col-md-6">
            <label class="form-label">Trạng thái</label
            ><select v-model="chapterForm.status" class="form-select">
              <option value="ACTIVE">Hoạt động</option>
              <option value="INACTIVE">Tạm ẩn</option>
            </select>
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel btn-action-outline" @click="chapterModal = false">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-save" :disabled="saving">
            <span v-if="saving" class="spinner-border spinner-border-sm"></span
            ><i v-else class="bi bi-check-lg"></i> Lưu chương
          </button>
        </div>
      </form>
    </div>

    <div v-if="lessonModal" class="modal-mask" @click.self="lessonModal = false">
      <form
        :class="[
          'app-card',
          'form-modal',
          'lesson-form-modal',
          { 'fullscreen-form-modal': ['INTERACTIVE_CONTENT', 'QUIZ'].includes(lessonForm.lessonType) }
        ]"
        @submit.prevent="saveLesson"
      >
        <div class="modal-heading">
          <div>
            <small>Bài học</small>
            <h2>{{ lessonForm.id ? 'Sửa bài học' : 'Thêm bài học' }}</h2>
          </div>
          <button type="button" class="btn-close" @click="lessonModal = false"></button>
        </div>
        <div class="row g-3">
          <div class="col-12">
            <div class="lesson-overview-grid">
              <div class="lesson-field lesson-field-title">
                <label class="form-label">Tên bài học</label>
                <input v-model.trim="lessonForm.title" class="form-control" required maxlength="500" />
              </div>
              <div class="lesson-field lesson-field-type">
                <label class="form-label">Loại bài</label>
                <select v-model="lessonForm.lessonType" class="form-select">
                  <option value="INTERACTIVE_VIDEO">Video tương tác</option>
                  <option value="VIDEO">Video</option>
                  <option value="QUIZ">Bài kiểm tra</option>
                  <option value="EDITOR">Bài học (soạn thảo + tài liệu)</option>
                  <option value="INTERACTIVE_CONTENT">Bài học tương tác</option>
                  <option value="ASSIGNMENT">Bài tập nộp file</option>
                </select>
              </div>
              <div class="lesson-field lesson-field-status">
                <label class="form-label">Trạng thái</label>
                <select v-model="lessonForm.status" class="form-select">
                  <option value="ACTIVE">Hoạt động</option>
                  <option value="INACTIVE">Tạm ẩn</option>
                </select>
              </div>
              <div class="lesson-field lesson-field-description">
                <label class="form-label">Mô tả</label>
                <textarea v-model.trim="lessonForm.description" class="form-control" rows="2"></textarea>
              </div>
              <div class="lesson-field lesson-field-order">
                <label class="form-label">Thứ tự</label>
                <input v-model.number="lessonForm.sortOrder" class="form-control" type="number" min="1" />
              </div>
              <div class="lesson-field lesson-field-score">
                <label class="form-label">Điểm đạt</label>
                <input v-model.number="lessonForm.passingScore" class="form-control" type="number" min="0" max="100" />
              </div>
              <label class="lesson-required-toggle" for="requiredLesson">
                <input id="requiredLesson" v-model="lessonForm.isRequired" class="form-check-input" type="checkbox" />
                <span>Bài học bắt buộc</span>
              </label>
            </div>
          </div>
          <div v-if="['EDITOR', 'DOCUMENT', 'INTERACTIVE_CONTENT'].includes(lessonForm.lessonType)" class="col-12">
            <label class="form-label"><i class="bi bi-pencil-square"></i> Nội dung soạn thảo</label>
            <div class="editor-toolbar">
              <button type="button" title="Chữ đậm" @click="formatEditor('bold')">
                <i class="bi bi-type-bold"></i>
              </button>
              <button type="button" title="Chữ nghiêng" @click="formatEditor('italic')">
                <i class="bi bi-type-italic"></i>
              </button>
              <button type="button" title="Danh sách" @click="formatEditor('insertUnorderedList')">
                <i class="bi bi-list-ul"></i>
              </button>
              <button type="button" title="Tiêu đề" @click="formatEditor('formatBlock', 'h3')">
                <i class="bi bi-type-h3"></i>
              </button>
            </div>
            <div ref="lessonEditor" class="lesson-rich-editor" contenteditable="true" @input="syncEditor"></div>
          </div>
          <template v-if="lessonForm.lessonType === 'INTERACTIVE_CONTENT'">
            <div class="col-12 interactive-authoring-heading">
              <div>
                <span class="builder-eyebrow">ĐỌC HIỂU VÀ TƯƠNG TÁC</span>
                <h3>Câu hỏi trong bài</h3>
                <p>Chọn câu hỏi dùng chung từ ngân hàng, sau đó cấu hình điểm và số lần thử riêng cho bài này.</p>
              </div>
              <div class="d-flex flex-wrap gap-2">
                <button type="button" class="btn btn-action-view btn-sm" @click="previewInteractive = true">
                  <i class="bi bi-eye"></i> Xem như học viên
                </button>
                <button type="button" class="btn btn-action-create btn-sm" @click="openQuickQuestion">
                  <i class="bi bi-plus-lg"></i> Tạo câu hỏi
                </button>
              </div>
            </div>
            <div class="col-md-6">
              <label class="form-label"><i class="bi bi-check2-circle"></i> Điều kiện hoàn thành</label>
              <select v-model="lessonForm.interactiveCompletionRule" class="form-select">
                <option value="REQUIRED_QUESTIONS">Hoàn thành câu hỏi bắt buộc</option>
                <option value="ALL_QUESTIONS">Trả lời tất cả câu hỏi</option>
                <option value="PASSING_SCORE">Đạt điểm tối thiểu</option>
              </select>
            </div>
            <div class="col-md-3">
              <label class="form-label"><i class="bi bi-bullseye"></i> Điểm đạt (%)</label>
              <input
                v-model.number="lessonForm.interactivePassingScore"
                class="form-control"
                type="number"
                min="0"
                max="100"
              />
            </div>
            <div class="col-md-3 interactive-checks">
              <label><input v-model="lessonForm.interactiveRequireReading" type="checkbox" /> Phải đọc hết bài</label>
              <label><input v-model="lessonForm.interactiveShowResult" type="checkbox" /> Hiện đúng / sai ngay</label>
              <label><input v-model="lessonForm.interactiveShowScore" type="checkbox" /> Hiện điểm</label>
            </div>
            <div class="col-12 interactive-question-workspace">
              <section class="interactive-bank-panel">
                <header class="interactive-panel-heading">
                  <div>
                    <span>NGÂN HÀNG CÂU HỎI</span>
                    <h4>Tìm và chọn câu hỏi</h4>
                  </div>
                  <strong>{{ interactiveQuestionTotal }} câu</strong>
                </header>
                <div class="interactive-bank-toolbar">
                  <label class="interactive-search-box">
                    <i class="bi bi-search"></i>
                    <input
                      v-model.trim="interactiveQuestionSearch"
                      class="form-control"
                      placeholder="Tìm nhanh theo nội dung câu hỏi..."
                    />
                  </label>
                  <select v-model="interactiveQuestionType" class="form-select" aria-label="Lọc loại câu hỏi">
                    <option value="">Tất cả loại câu hỏi</option>
                    <option value="SINGLE_CHOICE">Một lựa chọn</option>
                    <option value="MULTIPLE_CHOICE">Nhiều lựa chọn</option>
                    <option value="TRUE_FALSE">Đúng / Sai</option>
                    <option value="SHORT_ANSWER">Trả lời ngắn</option>
                  </select>
                </div>
                <div class="interactive-question-picker">
                  <div v-if="interactiveQuestionLoading" class="interactive-bank-state">
                    <span class="spinner-border spinner-border-sm"></span> Đang tìm câu hỏi...
                  </div>
                  <label
                    v-for="question in interactiveQuestionBank"
                    v-else
                    :key="question.id"
                    class="interactive-bank-row"
                  >
                    <input
                      :checked="isInteractiveQuestionSelected(question.id)"
                      type="checkbox"
                      class="form-check-input"
                      @change="toggleInteractiveQuestion(question, $event.target.checked)"
                    />
                    <span class="interactive-bank-copy">
                      <strong>{{ question.text }}</strong>
                      <small>{{ questionTypeLabel(question.type) }} · Mặc định {{ question.score }} điểm</small>
                    </span>
                  </label>
                  <p
                    v-if="!interactiveQuestionLoading && !interactiveQuestionBank.length"
                    class="interactive-bank-state"
                  >
                    Không tìm thấy câu hỏi phù hợp.
                  </p>
                </div>
                <small v-if="interactiveQuestionTotal > interactiveQuestionBank.length" class="interactive-result-note">
                  Đang hiển thị {{ interactiveQuestionBank.length }}/{{ interactiveQuestionTotal }} câu. Hãy tìm kiếm
                  hoặc lọc loại để thu hẹp kết quả.
                </small>
              </section>

              <section class="interactive-selected-panel">
                <header class="interactive-panel-heading">
                  <div>
                    <span>CÂU HỎI TRONG BÀI</span>
                    <h4>Sắp xếp và thiết lập</h4>
                  </div>
                  <strong>{{ lessonForm.interactiveMappings.length }} đã chọn</strong>
                </header>
                <div v-if="lessonForm.interactiveMappings.length" class="interactive-selected-list">
                  <article v-for="(mapping, index) in lessonForm.interactiveMappings" :key="mapping.questionId">
                    <span class="interactive-order">{{ index + 1 }}</span>
                    <div class="interactive-selected-copy">
                      <strong>{{ mapping.questionText }}</strong>
                      <small>{{ questionTypeLabel(mapping.questionType) }}</small>
                    </div>
                    <label>Điểm <input v-model.number="mapping.score" type="number" min="0" max="10000" /></label>
                    <label
                      >Lượt
                      <input
                        v-model.number="mapping.attemptLimit"
                        type="number"
                        min="1"
                        max="100"
                        :disabled="!mapping.allowRetry"
                    /></label>
                    <label class="compact-check"><input v-model="mapping.required" type="checkbox" /> Bắt buộc</label>
                    <label class="compact-check"><input v-model="mapping.allowRetry" type="checkbox" /> Thử lại</label>
                    <div class="interactive-order-actions" aria-label="Sắp xếp câu hỏi">
                      <button
                        type="button"
                        class="btn btn-action-view btn-sm"
                        title="Đưa câu hỏi lên"
                        :disabled="index === 0"
                        @click="moveInteractiveMapping(index, -1)"
                      >
                        <i class="bi bi-arrow-up"></i>
                      </button>
                      <button
                        type="button"
                        class="btn btn-action-view btn-sm"
                        title="Đưa câu hỏi xuống"
                        :disabled="index === lessonForm.interactiveMappings.length - 1"
                        @click="moveInteractiveMapping(index, 1)"
                      >
                        <i class="bi bi-arrow-down"></i>
                      </button>
                    </div>
                    <button
                      type="button"
                      class="btn btn-action-delete btn-sm"
                      title="Bỏ khỏi bài"
                      @click="removeInteractiveMapping(index)"
                    >
                      <i class="bi bi-trash"></i>
                    </button>
                  </article>
                </div>
                <div v-else class="interactive-selected-empty">
                  <i class="bi bi-ui-checks-grid"></i>
                  <strong>Chưa chọn câu hỏi</strong>
                  <span>Tìm câu hỏi ở cột bên trái và tích chọn để thêm vào bài học.</span>
                </div>
              </section>
            </div>
          </template>
          <template v-if="['EDITOR', 'DOCUMENT', 'ASSIGNMENT'].includes(lessonForm.lessonType)">
            <div class="col-12">
              <label class="form-label"><i class="bi bi-paperclip"></i> Tài liệu đính kèm</label>
              <input
                class="form-control"
                type="file"
                accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.zip,.txt,.png,.jpg,.jpeg"
                @change="selectLessonFile"
              />
              <small v-if="lessonForm.documentUrl" class="resource-path"
                ><i class="bi bi-check-circle"></i> {{ lessonForm.documentUrl }}</small
              >
              <small v-else-if="lessonForm.lessonType === 'EDITOR'" class="form-text">
                Không bắt buộc. Có thể vừa soạn nội dung phía trên, vừa đính kèm PDF, Word hoặc tài liệu khác.
              </small>
            </div>
          </template>
          <template v-if="lessonForm.lessonType === 'ASSIGNMENT'">
            <div class="col-md-6">
              <label class="form-label">Thư mục bài tập</label
              ><input
                v-model.trim="lessonForm.assignmentFolderName"
                class="form-control"
                maxlength="250"
                placeholder="VD: Bai-tap-chuong-1"
              />
            </div>
            <div class="col-md-6">
              <label class="form-label">Thời gian mở</label
              ><input v-model="lessonForm.assignmentStartAt" class="form-control" type="datetime-local" />
            </div>
            <div class="col-md-6">
              <label class="form-label">Hạn nộp</label
              ><input v-model="lessonForm.dueAt" class="form-control" type="datetime-local" />
            </div>
            <div class="col-md-3">
              <label class="form-label">Điểm tối đa</label
              ><input
                v-model.number="lessonForm.assignmentMaxScore"
                class="form-control"
                type="number"
                min="1"
                max="10000"
              />
            </div>
            <div class="col-md-3">
              <label class="form-label">Số lần nộp tối đa</label
              ><input
                v-model.number="lessonForm.maxSubmissionAttempts"
                class="form-control"
                type="number"
                min="1"
                max="20"
              />
            </div>
            <div class="col-md-6">
              <label class="form-label">Dung lượng nộp tối đa (MB)</label
              ><input
                v-model.number="lessonForm.maxSubmissionFileSizeMB"
                class="form-control"
                type="number"
                min="1"
                max="200"
              />
            </div>
            <div class="col-md-6 check-row">
              <input
                id="allowLate"
                v-model="lessonForm.allowLateSubmission"
                class="form-check-input"
                type="checkbox"
              /><label for="allowLate">Cho phép nộp trễ</label>
            </div>
          </template>
          <template v-if="lessonForm.lessonType === 'QUIZ'">
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-bullseye"></i> Điểm đạt (%)</label
              ><input
                v-model.number="lessonForm.quizPassingScore"
                class="form-control"
                type="number"
                min="0"
                max="100"
              />
            </div>
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-clock"></i> Thời gian (phút)</label
              ><input
                v-model.number="lessonForm.quizTimeLimitMinutes"
                class="form-control"
                type="number"
                min="1"
                max="600"
              />
            </div>
            <div class="col-md-4">
              <label class="form-label"><i class="bi bi-arrow-repeat"></i> Số lượt làm</label
              ><input v-model.number="lessonForm.quizMaxAttempts" class="form-control" type="number" min="1" max="20" />
            </div>
            <div class="col-12 check-row">
              <input
                id="shuffleQuiz"
                v-model="lessonForm.quizShuffleQuestions"
                class="form-check-input"
                type="checkbox"
              />
              <label for="shuffleQuiz">Đảo thứ tự câu hỏi khi học viên làm bài</label>
            </div>
            <div class="col-12">
              <div class="quiz-bank-heading">
                <div>
                  <span class="builder-eyebrow">SOẠN BÀI KIỂM TRA</span>
                  <h3 class="mb-0">Câu hỏi trong bài</h3>
                </div>
                <div class="quiz-bank-heading__actions">
                  <span class="quiz-bank-selected">{{ lessonForm.quizQuestionIds.length }} đã chọn</span>
                  <RouterLink to="/cms/questions" class="btn btn-action-view btn-sm"
                    ><i class="bi bi-plus-lg"></i> Quản lý ngân hàng</RouterLink
                  >
                </div>
              </div>
              <div class="quiz-question-workspace">
                <section class="quiz-bank-panel">
                  <header class="quiz-workspace-heading">
                    <div>
                      <span>NGÂN HÀNG CÂU HỎI</span>
                      <h4>Tìm và chọn câu hỏi</h4>
                    </div>
                    <strong>{{ quizQuestionTotal }} câu</strong>
                  </header>
                  <div class="quiz-bank-toolbar">
                    <label class="quiz-search-box">
                      <i class="bi bi-search"></i>
                      <input
                        v-model.trim="quizQuestionSearch"
                        class="form-control"
                        placeholder="Tìm nhanh theo nội dung câu hỏi..."
                        aria-label="Tìm nhanh câu hỏi trong ngân hàng"
                      />
                    </label>
                    <select v-model="quizQuestionType" class="form-select" aria-label="Lọc loại câu hỏi bài kiểm tra">
                      <option value="">Tất cả loại câu hỏi</option>
                      <option value="SINGLE_CHOICE">Một lựa chọn</option>
                      <option value="MULTIPLE_CHOICE">Nhiều lựa chọn</option>
                      <option value="TRUE_FALSE">Đúng / Sai</option>
                      <option value="SHORT_ANSWER">Trả lời ngắn</option>
                    </select>
                  </div>
                  <div class="quiz-question-picker">
                    <div v-if="quizQuestionLoading" class="quiz-bank-state">
                      <span class="spinner-border spinner-border-sm"></span> Đang tìm câu hỏi...
                    </div>
                    <template v-else>
                      <label
                        v-for="question in quizQuestionBank"
                        :key="question.id"
                        :class="['quiz-question-option', { 'is-selected': isQuizQuestionSelected(question.id) }]"
                      >
                        <input
                          :checked="isQuizQuestionSelected(question.id)"
                          type="checkbox"
                          class="form-check-input"
                          @change="toggleQuizQuestion(question, $event.target.checked)"
                        />
                        <span
                          ><strong>{{ question.text }}</strong
                          ><small>{{ questionTypeLabel(question.type) }} · {{ question.score }} điểm</small></span
                        >
                      </label>
                      <p v-if="!quizQuestionBank.length" class="quiz-bank-state mb-0">
                        Không tìm thấy câu hỏi phù hợp với bộ lọc.
                      </p>
                    </template>
                  </div>
                  <small v-if="quizQuestionTotal > quizQuestionBank.length" class="quiz-bank-result-note">
                    Đang hiển thị {{ quizQuestionBank.length }}/{{ quizQuestionTotal }} câu. Hãy nhập từ khóa hoặc chọn
                    loại câu hỏi để thu hẹp kết quả.
                  </small>
                </section>

                <section class="quiz-selected-panel">
                  <header class="quiz-workspace-heading">
                    <div>
                      <span>CÂU HỎI TRONG BÀI</span>
                      <h4>Sắp xếp thứ tự làm bài</h4>
                    </div>
                    <strong>{{ quizSelectedQuestions.length }} đã chọn</strong>
                  </header>
                  <div v-if="quizSelectedQuestions.length" class="quiz-selected-list">
                    <article
                      v-for="(question, index) in quizSelectedQuestions"
                      :key="question.id"
                      class="quiz-selected-item"
                    >
                      <span class="quiz-selected-order">{{ index + 1 }}</span>
                      <div class="quiz-selected-copy">
                        <strong>{{ question.text }}</strong>
                        <small>{{ questionTypeLabel(question.type) }} · {{ question.score }} điểm</small>
                      </div>
                      <div class="quiz-order-actions" aria-label="Sắp xếp thứ tự câu hỏi">
                        <button
                          type="button"
                          class="btn btn-action-view btn-sm"
                          title="Đưa câu hỏi lên"
                          :disabled="index === 0"
                          @click="moveQuizQuestion(index, -1)"
                        >
                          <i class="bi bi-arrow-up"></i>
                        </button>
                        <button
                          type="button"
                          class="btn btn-action-view btn-sm"
                          title="Đưa câu hỏi xuống"
                          :disabled="index === quizSelectedQuestions.length - 1"
                          @click="moveQuizQuestion(index, 1)"
                        >
                          <i class="bi bi-arrow-down"></i>
                        </button>
                      </div>
                      <button
                        type="button"
                        class="btn btn-action-delete btn-action-outline btn-sm"
                        title="Bỏ câu hỏi khỏi bài kiểm tra"
                        @click="removeQuizQuestion(index)"
                      >
                        <i class="bi bi-trash"></i>
                      </button>
                    </article>
                  </div>
                  <div v-else class="quiz-selected-empty">
                    <i class="bi bi-ui-checks-grid"></i>
                    <strong>Chưa chọn câu hỏi</strong>
                    <span>Tìm câu hỏi ở cột bên trái và tích chọn để thêm vào bài kiểm tra.</span>
                  </div>
                </section>
              </div>
            </div>
          </template>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel btn-action-outline" @click="lessonModal = false">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-save" :disabled="saving">
            <span v-if="saving" class="spinner-border spinner-border-sm"></span
            ><i v-else class="bi bi-check-lg"></i> Lưu bài học
          </button>
        </div>
      </form>
    </div>

    <div v-if="videoModal" class="modal-mask" @click.self="videoModal = false">
      <div class="app-card library-modal">
        <div class="modal-heading">
          <div>
            <small>Video dùng chung</small>
            <h2>Chọn video cho “{{ targetLesson?.title }}”</h2>
            <p>Một video thư viện có thể gắn vào nhiều môn và bài học.</p>
          </div>
          <button class="btn-close" @click="videoModal = false"></button>
        </div>
        <div class="library-toolbar">
          <input
            v-model.trim="videoSearch"
            class="form-control"
            placeholder="Tìm theo tên video hoặc tên file..."
          /><RouterLink class="btn btn-action-create text-nowrap" to="/cms/videos"
            ><i class="bi bi-plus-lg"></i> Thêm video mới</RouterLink
          >
        </div>
        <div class="video-list">
          <button
            v-for="asset in videoAssets"
            :key="asset.id"
            class="video-item"
            :disabled="saving"
            @click="attachVideo(asset)"
          >
            <span class="video-icon"><i class="bi bi-play-fill"></i></span>
            <div>
              <strong>{{ asset.title }}</strong
              ><small>{{ formatTime(asset.durationSeconds) }} • Đang dùng ở {{ asset.usageCount }} bài</small>
            </div>
            <span class="btn btn-blue btn-sm">Chọn</span>
          </button>
          <div v-if="!videoAssets.length" class="p-4 text-center text-secondary">Không tìm thấy video phù hợp.</div>
        </div>
      </div>
    </div>

    <div v-if="quickQuestionModal" class="modal-mask nested-modal-mask" @click.self="quickQuestionModal = false">
      <form class="app-card quick-question-modal" @submit.prevent="saveQuickQuestion">
        <div class="modal-heading">
          <div>
            <small>Ngân hàng câu hỏi</small>
            <h2>Tạo nhanh câu hỏi</h2>
          </div>
          <button type="button" class="btn-close" @click="quickQuestionModal = false"></button>
        </div>
        <div class="row g-3">
          <div class="col-md-4">
            <label class="form-label">Loại câu hỏi</label
            ><select v-model="quickQuestion.questionType" class="form-select" @change="normalizeQuickQuestion">
              <option value="SINGLE_CHOICE">Một lựa chọn</option>
              <option value="MULTIPLE_CHOICE">Nhiều lựa chọn</option>
              <option value="TRUE_FALSE">Đúng / Sai</option>
              <option value="SHORT_ANSWER">Trả lời ngắn</option>
            </select>
          </div>
          <div class="col-md-8">
            <label class="form-label">Nội dung câu hỏi</label
            ><input v-model.trim="quickQuestion.questionText" class="form-control" required />
          </div>
          <div class="col-md-8">
            <label class="form-label">Giải thích</label
            ><textarea v-model.trim="quickQuestion.explanation" class="form-control" rows="2"></textarea>
          </div>
          <div class="col-md-4">
            <label class="form-label">Điểm mặc định</label
            ><input v-model.number="quickQuestion.defaultScore" class="form-control" type="number" min="0" />
          </div>
          <template v-if="quickQuestion.questionType !== 'SHORT_ANSWER'">
            <div
              v-for="(option, index) in quickQuestion.options"
              :key="option.optionCode"
              class="col-12 quick-option-row"
            >
              <input v-model.trim="option.optionCode" class="form-control" required />
              <input v-model.trim="option.optionText" class="form-control" required />
              <label
                ><input
                  v-model="option.isCorrect"
                  :type="quickQuestion.questionType === 'MULTIPLE_CHOICE' ? 'checkbox' : 'radio'"
                  name="quick-correct"
                  @change="selectQuickCorrect(index)"
                />
                Đúng</label
              >
            </div>
            <button
              v-if="!['TRUE_FALSE'].includes(quickQuestion.questionType)"
              type="button"
              class="btn btn-action-view btn-sm quick-add-option"
              @click="addQuickOption"
            >
              <i class="bi bi-plus-lg"></i> Thêm đáp án
            </button>
          </template>
          <div v-else class="col-12">
            <label class="form-label">Đáp án mẫu</label
            ><input v-model.trim="quickQuestion.shortAnswer" class="form-control" required />
          </div>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel btn-action-outline" @click="quickQuestionModal = false">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-save" :disabled="saving"><i class="bi bi-check-lg"></i> Lưu và chọn</button>
        </div>
      </form>
    </div>

    <div v-if="previewInteractive" class="modal-mask" @click.self="previewInteractive = false">
      <div class="app-card interactive-preview-modal">
        <div class="modal-heading">
          <div>
            <small>Xem như học viên</small>
            <h2>{{ lessonForm.title || 'Bài học tương tác' }}</h2>
          </div>
          <button class="btn-close" @click="previewInteractive = false"></button>
        </div>
        <div class="interactive-preview-layout">
          <main>
            <article
              class="interactive-preview-content"
              v-html="sanitizeLearningHtml(lessonForm.contentHtml || '<p>Chưa có nội dung bài học.</p>')"
            ></article>
            <article
              v-for="(mapping, index) in lessonForm.interactiveMappings"
              :key="mapping.questionId"
              class="preview-question-card"
            >
              <small>CÂU {{ index + 1 }}</small>
              <h3>{{ mapping.questionText }}</h3>
              <label v-for="option in mapping.options || []" :key="option.code"
                ><input :type="mapping.questionType === 'MULTIPLE_CHOICE' ? 'checkbox' : 'radio'" disabled />
                <b>{{ option.code }}</b> {{ option.text }}</label
              >
              <textarea
                v-if="mapping.questionType === 'SHORT_ANSWER'"
                class="form-control"
                rows="2"
                disabled
                placeholder="Học viên nhập câu trả lời..."
              ></textarea>
              <button type="button" class="btn btn-action-save btn-sm" disabled>
                <i class="bi bi-send-check"></i> Kiểm tra đáp án
              </button>
            </article>
          </main>
          <aside>
            <h3>Câu hỏi</h3>
            <button v-for="(mapping, index) in lessonForm.interactiveMappings" :key="mapping.questionId">
              <span>{{ String(index + 1).padStart(2, '0') }}</span
              >{{ mapping.questionText }}
            </button>
          </aside>
        </div>
      </div>
    </div>

    <div v-if="deleteTarget" class="modal-mask" @click.self="deleteTarget = null">
      <div class="app-card confirm-modal">
        <span class="delete-icon"><i class="bi bi-trash"></i></span>
        <h2>Xóa {{ deleteTarget.type === 'chapter' ? 'chương' : 'bài học' }}?</h2>
        <p>
          {{
            deleteTarget.type === 'chapter'
              ? 'Các bài học bên trong cũng sẽ bị ẩn khỏi hệ thống.'
              : 'Bài học sẽ bị ẩn khỏi khóa học và LMS.'
          }}
        </p>
        <div class="modal-actions">
          <button class="btn btn-action-cancel btn-action-outline" @click="deleteTarget = null">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-delete" :disabled="saving" @click="removeTarget">
            <i class="bi bi-trash"></i> Xóa
          </button>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { nextTick, onMounted, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import { formatInteractionTime } from '../../utils/learningRules'
import { sanitizeLearningHtml } from '../../utils/sanitizeHtml'

const route = useRoute(),
  courseId = Number(route.params.id),
  course = reactive({ id: courseId, title: 'Khóa học' }),
  chapters = ref([]),
  loading = ref(true),
  saving = ref(false),
  message = ref(''),
  messageType = ref('success')
const chapterModal = ref(false),
  lessonModal = ref(false),
  videoModal = ref(false),
  deleteTarget = ref(null),
  targetLesson = ref(null),
  videoAssets = ref([]),
  quizQuestionBank = ref([]),
  quizSelectedQuestions = ref([]),
  interactiveQuestionBank = ref([]),
  interactiveOriginalIds = ref([]),
  quickQuestionModal = ref(false),
  previewInteractive = ref(false),
  videoSearch = ref(''),
  quizQuestionSearch = ref(''),
  quizQuestionType = ref(''),
  quizQuestionTotal = ref(0),
  quizQuestionLoading = ref(false),
  interactiveQuestionSearch = ref(''),
  interactiveQuestionType = ref(''),
  interactiveQuestionTotal = ref(0),
  interactiveQuestionLoading = ref(false)
const lessonEditor = ref(null),
  lessonFile = ref(null)
const chapterForm = reactive(blankChapter()),
  lessonForm = reactive(blankLesson()),
  quickQuestion = reactive(blankQuickQuestion())
const collapsedChapterIds = ref(new Set())
const chapterCollapseStorageKey = `cms-content:${courseId}:collapsed-chapters`
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const formatTime = formatInteractionTime
let videoTimer
let quizQuestionTimer
let interactiveQuestionTimer
let chapterCollapseStateLoaded = false
watch(videoSearch, () => {
  clearTimeout(videoTimer)
  videoTimer = setTimeout(loadVideoAssets, 250)
})
watch([quizQuestionSearch, quizQuestionType], () => {
  clearTimeout(quizQuestionTimer)
  if (lessonForm.lessonType !== 'QUIZ' || !lessonModal.value) return
  quizQuestionTimer = setTimeout(loadQuizQuestionBank, 250)
})
watch([interactiveQuestionSearch, interactiveQuestionType], () => {
  clearTimeout(interactiveQuestionTimer)
  interactiveQuestionTimer = setTimeout(loadInteractiveQuestionBank, 250)
})
watch(
  () => lessonForm.lessonType,
  (type) => {
    if (type === 'QUIZ' && !quizQuestionBank.value.length) void loadQuizEditor(0)
    if (type === 'INTERACTIVE_CONTENT' && !interactiveQuestionBank.value.length) void loadInteractiveEditor(0)
  }
)
onMounted(load)

async function load() {
  loading.value = true
  try {
    const [courseData, content] = await Promise.all([
      axiosClient.get(`/courses/${courseId}`),
      axiosClient.get(`/courses/${courseId}/content`, { params: { _fresh: Date.now() } })
    ])
    course.title = pick(courseData, 'Title', 'title') || course.title
    const chapterRows = pick(content, 'chapters', 'Chapters') || [],
      lessonRows = pick(content, 'lessons', 'Lessons') || []
    chapters.value = chapterRows.map((row, index) => {
      const id = Number(pick(row, 'Id', 'id'))
      return {
        id,
        title: pick(row, 'Title', 'title'),
        description: pick(row, 'Description', 'description') || '',
        sortOrder: Number(pick(row, 'SortOrder', 'sortOrder') || index + 1),
        status: pick(row, 'Status', 'status') || 'ACTIVE',
        lessons: lessonRows.filter((x) => Number(pick(x, 'ChapterId', 'chapterId')) === id).map(mapLesson)
      }
    })
    syncChapterCollapseState()
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    loading.value = false
  }
}
function syncChapterCollapseState() {
  const validIds = new Set(chapters.value.map((chapter) => chapter.id))
  if (!chapterCollapseStateLoaded) {
    try {
      const stored = sessionStorage.getItem(chapterCollapseStorageKey)
      collapsedChapterIds.value =
        stored === null
          ? new Set(validIds)
          : new Set(
              JSON.parse(stored)
                .map(Number)
                .filter((id) => validIds.has(id))
            )
    } catch {
      collapsedChapterIds.value = new Set(validIds)
    }
    chapterCollapseStateLoaded = true
  } else {
    collapsedChapterIds.value = new Set([...collapsedChapterIds.value].filter((id) => validIds.has(id)))
  }
  persistChapterCollapseState()
}
function persistChapterCollapseState() {
  try {
    sessionStorage.setItem(chapterCollapseStorageKey, JSON.stringify([...collapsedChapterIds.value]))
  } catch {
    // Trình duyệt có thể chặn sessionStorage; chức năng thu gọn vẫn hoạt động trong trang hiện tại.
  }
}
function isChapterCollapsed(chapterId) {
  return collapsedChapterIds.value.has(Number(chapterId))
}
function toggleChapter(chapterId) {
  const next = new Set(collapsedChapterIds.value)
  const id = Number(chapterId)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  collapsedChapterIds.value = next
  persistChapterCollapseState()
}
function collapseAllChapters() {
  collapsedChapterIds.value = new Set(chapters.value.map((chapter) => chapter.id))
  persistChapterCollapseState()
}
function expandAllChapters() {
  collapsedChapterIds.value = new Set()
  persistChapterCollapseState()
}
function mapLesson(row, index) {
  return {
    id: Number(pick(row, 'Id', 'id')),
    chapterId: Number(pick(row, 'ChapterId', 'chapterId')),
    title: pick(row, 'Title', 'title'),
    description: pick(row, 'Description', 'description') || '',
    lessonType: pick(row, 'LessonType', 'lessonType') || 'INTERACTIVE_VIDEO',
    durationSeconds: Number(pick(row, 'DurationSeconds', 'durationSeconds') || 0),
    sortOrder: Number(pick(row, 'SortOrder', 'sortOrder') || index + 1),
    isRequired: Boolean(pick(row, 'IsRequired', 'isRequired')),
    passingScore: Number(pick(row, 'PassingScore', 'passingScore') || 0),
    status: pick(row, 'Status', 'status') || 'ACTIVE',
    videoId: Number(pick(row, 'VideoId', 'videoId') || 0),
    videoAssetId: Number(pick(row, 'VideoAssetId', 'videoAssetId') || 0),
    videoTitle: pick(row, 'VideoTitle', 'videoTitle') || '',
    canEditVideo: Boolean(pick(row, 'CanEditVideo', 'canEditVideo')),
    contentHtml: pick(row, 'ContentHtml', 'contentHtml') || '',
    documentUrl: pick(row, 'DocumentUrl', 'documentUrl') || '',
    assignmentFolderName: pick(row, 'AssignmentFolderName', 'assignmentFolderName') || '',
    assignmentStartAt: toLocalDateTime(pick(row, 'AssignmentStartAt', 'assignmentStartAt')),
    dueAt: toLocalDateTime(pick(row, 'DueAt', 'dueAt')),
    assignmentMaxScore: Number(pick(row, 'AssignmentMaxScore', 'assignmentMaxScore') || 100),
    maxSubmissionAttempts: Number(pick(row, 'MaxSubmissionAttempts', 'maxSubmissionAttempts') || 3),
    maxSubmissionFileSizeMB: Number(pick(row, 'MaxSubmissionFileSizeMB', 'maxSubmissionFileSizeMB') || 50),
    allowLateSubmission: Boolean(pick(row, 'AllowLateSubmission', 'allowLateSubmission')),
    interactiveCompletionRule: 'REQUIRED_QUESTIONS',
    interactiveRequireReading: true,
    interactivePassingScore: 70,
    interactiveShowResult: true,
    interactiveShowScore: true,
    interactiveMappings: []
  }
}
function blankChapter() {
  return { id: 0, title: '', description: '', sortOrder: 1, status: 'ACTIVE' }
}
function blankLesson() {
  return {
    id: 0,
    chapterId: 0,
    title: '',
    description: '',
    lessonType: 'INTERACTIVE_VIDEO',
    durationSeconds: 0,
    sortOrder: 1,
    isRequired: true,
    passingScore: 0,
    status: 'ACTIVE',
    contentHtml: '',
    documentUrl: '',
    assignmentFolderName: '',
    assignmentStartAt: '',
    dueAt: '',
    assignmentMaxScore: 100,
    maxSubmissionAttempts: 3,
    maxSubmissionFileSizeMB: 50,
    allowLateSubmission: false,
    quizPassingScore: 50,
    quizTimeLimitMinutes: 30,
    quizMaxAttempts: 1,
    quizShuffleQuestions: false,
    quizQuestionIds: [],
    interactiveCompletionRule: 'REQUIRED_QUESTIONS',
    interactiveRequireReading: true,
    interactivePassingScore: 70,
    interactiveShowResult: true,
    interactiveShowScore: true,
    interactiveMappings: []
  }
}
function blankQuickQuestion() {
  return {
    questionType: 'SINGLE_CHOICE',
    questionText: '',
    explanation: '',
    defaultScore: 10,
    shortAnswer: '',
    options: [
      { optionCode: 'A', optionText: '', isCorrect: true },
      { optionCode: 'B', optionText: '', isCorrect: false }
    ]
  }
}
function openChapter(item = null) {
  Object.assign(
    chapterForm,
    item
      ? {
          id: item.id,
          title: item.title,
          description: item.description,
          sortOrder: item.sortOrder,
          status: item.status
        }
      : { ...blankChapter(), sortOrder: chapters.value.length + 1 }
  )
  chapterModal.value = true
}
async function openLesson(chapter, item = null) {
  Object.assign(
    lessonForm,
    item ? { ...item } : { ...blankLesson(), chapterId: chapter.id, sortOrder: chapter.lessons.length + 1 }
  )
  lessonForm.chapterId = chapter.id
  // Dữ liệu DOCUMENT cũ được mở bằng loại Bài học hợp nhất và sẽ chuyển sang EDITOR khi lưu.
  if (lessonForm.lessonType === 'DOCUMENT') lessonForm.lessonType = 'EDITOR'
  lessonFile.value = null
  if (lessonForm.lessonType === 'QUIZ') await loadQuizEditor(lessonForm.id)
  if (lessonForm.lessonType === 'INTERACTIVE_CONTENT') await loadInteractiveEditor(lessonForm.id)
  lessonModal.value = true
  nextTick(() => {
    if (lessonEditor.value) lessonEditor.value.innerHTML = lessonForm.contentHtml || ''
  })
}
async function saveChapter() {
  saving.value = true
  try {
    const body = {
      title: chapterForm.title,
      description: chapterForm.description || null,
      sortOrder: chapterForm.sortOrder,
      status: chapterForm.status
    }
    if (chapterForm.id) await axiosClient.put(`/chapters/${chapterForm.id}`, body)
    else await axiosClient.post(`/courses/${courseId}/chapters`, body)
    chapterModal.value = false
    await load()
    show('Đã lưu chương vào SQL.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
async function saveLesson() {
  saving.value = true
  try {
    const body = {
      title: lessonForm.title,
      description: lessonForm.description || null,
      lessonType: lessonForm.lessonType,
      durationSeconds: Math.max(0, Number(lessonForm.durationSeconds) || 0),
      sortOrder: lessonForm.sortOrder,
      isRequired: lessonForm.isRequired,
      passingScore: Number(lessonForm.passingScore) || 0,
      contentHtml: ['EDITOR', 'DOCUMENT', 'INTERACTIVE_CONTENT'].includes(lessonForm.lessonType)
        ? lessonForm.contentHtml || null
        : null,
      documentUrl: ['EDITOR', 'DOCUMENT', 'ASSIGNMENT'].includes(lessonForm.lessonType)
        ? lessonForm.documentUrl || null
        : null,
      assignmentFolderName: lessonForm.lessonType === 'ASSIGNMENT' ? lessonForm.assignmentFolderName || null : null,
      assignmentStartAt:
        lessonForm.lessonType === 'ASSIGNMENT' && lessonForm.assignmentStartAt
          ? new Date(lessonForm.assignmentStartAt).toISOString()
          : null,
      dueAt:
        lessonForm.lessonType === 'ASSIGNMENT' && lessonForm.dueAt ? new Date(lessonForm.dueAt).toISOString() : null,
      assignmentMaxScore: Number(lessonForm.assignmentMaxScore) || 100,
      maxSubmissionAttempts: Number(lessonForm.maxSubmissionAttempts) || 3,
      maxSubmissionFileSizeMB: Number(lessonForm.maxSubmissionFileSizeMB) || 50,
      allowLateSubmission: lessonForm.lessonType === 'ASSIGNMENT' && lessonForm.allowLateSubmission,
      status: lessonForm.status
    }
    let lessonId = lessonForm.id
    if (lessonId) await axiosClient.put(`/lessons/${lessonId}`, body)
    else {
      const result = await axiosClient.post(`/chapters/${lessonForm.chapterId}/lessons`, body)
      lessonId = Number(pick(result, 'id', 'Id'))
    }
    if (lessonFile.value && lessonId) {
      const uploadBody = new FormData()
      uploadBody.append('file', lessonFile.value)
      const uploaded = await axiosClient.post(`/learning-files/lessons/${lessonId}/resource`, uploadBody)
      body.documentUrl = pick(uploaded, 'fileUrl', 'FileUrl')
      await axiosClient.put(`/lessons/${lessonId}`, body)
    }
    if (lessonForm.lessonType === 'QUIZ') {
      await axiosClient.put(`/lessons/${lessonId}/quiz`, {
        title: lessonForm.title,
        description: lessonForm.description || null,
        passingScore: Number(lessonForm.quizPassingScore) || 0,
        timeLimitMinutes: Number(lessonForm.quizTimeLimitMinutes) || null,
        maxAttempts: Number(lessonForm.quizMaxAttempts) || 1,
        shuffleQuestions: lessonForm.quizShuffleQuestions,
        questionIds: lessonForm.quizQuestionIds
      })
    }
    if (lessonForm.lessonType === 'INTERACTIVE_CONTENT') await saveInteractiveEditor(lessonId)
    lessonModal.value = false
    await load()
    show('Đã lưu bài học.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
function askDelete(type, item) {
  deleteTarget.value = { type, item }
}
async function removeTarget() {
  saving.value = true
  try {
    await axiosClient.delete(
      `/${deleteTarget.value.type === 'chapter' ? 'chapters' : 'lessons'}/${deleteTarget.value.item.id}`
    )
    deleteTarget.value = null
    await load()
    show('Đã xóa nội dung khỏi môn học lớp.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
async function openVideoPicker(lesson) {
  targetLesson.value = lesson
  videoSearch.value = ''
  await loadVideoAssets()
  videoModal.value = true
}
async function loadVideoAssets() {
  try {
    const rows = await axiosClient.get('/video-library', {
      params: { search: videoSearch.value || undefined, _fresh: Date.now() }
    })
    videoAssets.value = (Array.isArray(rows) ? rows : [])
      .map((row) => ({
        id: Number(pick(row, 'Id', 'id')),
        videoId: Number(pick(row, 'VideoId', 'videoId') || pick(row, 'FirstVideoId', 'firstVideoId') || 0),
        title: pick(row, 'Title', 'title'),
        durationSeconds: Number(pick(row, 'DurationSeconds', 'durationSeconds') || 0),
        usageCount: Number(pick(row, 'UsageCount', 'usageCount') || 0)
      }))
      .filter((x) => x.videoId > 0)
  } catch (error) {
    show(error.message, 'danger')
  }
}
async function attachVideo(asset) {
  saving.value = true
  try {
    await axiosClient.put(`/lessons/${targetLesson.value.id}/video/${asset.videoId}`)
    videoModal.value = false
    await load()
    show(`Đã tham chiếu “${asset.title}” cho bài học. Không tạo bản sao video; kết quả học vẫn tách riêng theo bài.`)
    targetLesson.value = null
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
function lessonTypeLabel(type) {
  return (
    {
      INTERACTIVE_VIDEO: 'Video tương tác',
      VIDEO: 'Video',
      QUIZ: 'Bài kiểm tra',
      DOCUMENT: 'Bài học',
      EDITOR: 'Bài học',
      ASSIGNMENT: 'Bài tập nộp file',
      INTERACTIVE_CONTENT: 'Bài học tương tác'
    }[type] || type
  )
}
function lessonTypeIcon(type) {
  return (
    {
      INTERACTIVE_VIDEO: 'bi-play-circle',
      VIDEO: 'bi-camera-video',
      QUIZ: 'bi-ui-checks-grid',
      DOCUMENT: 'bi-file-earmark-pdf',
      EDITOR: 'bi-journal-text',
      ASSIGNMENT: 'bi-clipboard2-check',
      INTERACTIVE_CONTENT: 'bi-journal-check'
    }[type] || 'bi-file-earmark-text'
  )
}
function lessonTypeClass(type) {
  return `type-${String(type || 'document')
    .toLowerCase()
    .replaceAll('_', '-')}`
}
function questionTypeLabel(type) {
  return (
    {
      SINGLE_CHOICE: 'Một lựa chọn',
      MULTIPLE_CHOICE: 'Nhiều lựa chọn',
      TRUE_FALSE: 'Đúng / Sai',
      SHORT_ANSWER: 'Trả lời ngắn'
    }[type] || type
  )
}
async function loadQuizEditor(lessonId) {
  quizQuestionSearch.value = ''
  quizQuestionType.value = ''
  lessonForm.quizQuestionIds = []
  quizSelectedQuestions.value = []
  await loadQuizQuestionBank()
  if (!lessonId) return
  const data = await axiosClient.get(`/lessons/${lessonId}/quiz`)
  const quiz = pick(data, 'Quiz', 'quiz')
  if (!quiz) return
  lessonForm.quizPassingScore = Number(pick(quiz, 'PassingScore', 'passingScore') || 50)
  lessonForm.quizTimeLimitMinutes = Number(pick(quiz, 'TimeLimitMinutes', 'timeLimitMinutes') || 0) || null
  lessonForm.quizMaxAttempts = Number(pick(quiz, 'MaxAttempts', 'maxAttempts') || 1)
  lessonForm.quizShuffleQuestions = Boolean(pick(quiz, 'ShuffleQuestions', 'shuffleQuestions'))
  quizSelectedQuestions.value = (pick(data, 'Questions', 'questions') || []).map(mapQuizQuestion)
  lessonForm.quizQuestionIds = quizSelectedQuestions.value.map((question) => question.id)
}
async function loadQuizQuestionBank() {
  quizQuestionLoading.value = true
  try {
    const bank = await axiosClient.get('/questions', {
      params: {
        search: quizQuestionSearch.value || undefined,
        type: quizQuestionType.value || undefined,
        page: 1,
        pageSize: 100,
        _fresh: Date.now()
      }
    })
    quizQuestionBank.value = (pick(bank, 'items', 'Items') || []).map(mapQuizQuestion)
    quizSelectedQuestions.value = quizSelectedQuestions.value.map((selected) => {
      const current = quizQuestionBank.value.find((question) => question.id === selected.id)
      return current || selected
    })
    quizQuestionTotal.value = Number(pick(bank, 'total', 'Total') || quizQuestionBank.value.length)
  } catch (error) {
    quizQuestionBank.value = []
    quizQuestionTotal.value = 0
    show(error.message, 'danger')
  } finally {
    quizQuestionLoading.value = false
  }
}
function mapQuizQuestion(row) {
  const id = Number(pick(row, 'QuestionID', 'questionID', 'Id', 'id'))
  return {
    id,
    text: pick(row, 'QuestionText', 'questionText') || `Câu hỏi #${id}`,
    type: pick(row, 'QuestionType', 'questionType') || '',
    score: Number(pick(row, 'Score', 'score', 'DefaultScore', 'defaultScore') || 0)
  }
}
function isQuizQuestionSelected(questionId) {
  return lessonForm.quizQuestionIds.includes(Number(questionId))
}
function toggleQuizQuestion(question, checked) {
  const id = Number(question.id)
  if (checked) {
    if (!isQuizQuestionSelected(id)) lessonForm.quizQuestionIds.push(id)
    if (!quizSelectedQuestions.value.some((item) => item.id === id)) {
      quizSelectedQuestions.value.push({ ...question, id })
    }
    return
  }
  lessonForm.quizQuestionIds = lessonForm.quizQuestionIds.filter((item) => Number(item) !== id)
  quizSelectedQuestions.value = quizSelectedQuestions.value.filter((item) => item.id !== id)
}
function moveQuizQuestion(index, offset) {
  const target = index + offset
  if (target < 0 || target >= quizSelectedQuestions.value.length) return
  const next = [...quizSelectedQuestions.value]
  const [question] = next.splice(index, 1)
  next.splice(target, 0, question)
  quizSelectedQuestions.value = next
  lessonForm.quizQuestionIds = next.map((item) => item.id)
}
function removeQuizQuestion(index) {
  const question = quizSelectedQuestions.value[index]
  if (question) toggleQuizQuestion(question, false)
}
async function loadInteractiveEditor(lessonId) {
  interactiveQuestionSearch.value = ''
  interactiveQuestionType.value = ''
  await loadInteractiveQuestionBank()
  lessonForm.interactiveMappings = []
  interactiveOriginalIds.value = []
  if (!lessonId) return
  const data = await axiosClient.get(`/lessons/${lessonId}/interactive-content`, { params: { _fresh: Date.now() } })
  const settings = pick(data, 'Settings', 'settings') || {}
  lessonForm.interactiveCompletionRule = pick(settings, 'CompletionRule', 'completionRule') || 'REQUIRED_QUESTIONS'
  lessonForm.interactiveRequireReading = Boolean(pick(settings, 'RequireReading', 'requireReading') ?? true)
  lessonForm.interactivePassingScore = Number(pick(settings, 'PassingScore', 'passingScore') || 70)
  lessonForm.interactiveShowResult = Boolean(pick(settings, 'ShowResultImmediately', 'showResultImmediately') ?? true)
  lessonForm.interactiveShowScore = Boolean(pick(settings, 'ShowScore', 'showScore') ?? true)
  lessonForm.interactiveMappings = (pick(data, 'Interactions', 'interactions') || []).map((row, index) => ({
    id: Number(pick(row, 'ContentInteractionID', 'contentInteractionID')),
    questionId: Number(pick(row, 'QuestionID', 'questionID')),
    questionText: pick(row, 'QuestionText', 'questionText') || '',
    questionType: pick(row, 'QuestionType', 'questionType') || '',
    required: Boolean(pick(row, 'Required', 'required')),
    allowRetry: Boolean(pick(row, 'AllowRetry', 'allowRetry')),
    score: Number(pick(row, 'Score', 'score') || 0),
    attemptLimit: Number(pick(row, 'AttemptLimit', 'attemptLimit') || 1),
    sortOrder: Number(pick(row, 'SortOrder', 'sortOrder') || index + 1),
    status: pick(row, 'Status', 'status') || 'ACTIVE',
    options: parseQuestionOptions(pick(row, 'Options', 'options'))
  }))
  interactiveOriginalIds.value = lessonForm.interactiveMappings.map((item) => item.id)
}
async function loadInteractiveQuestionBank() {
  interactiveQuestionLoading.value = true
  try {
    const bank = await axiosClient.get('/questions', {
      params: {
        search: interactiveQuestionSearch.value || undefined,
        type: interactiveQuestionType.value || undefined,
        page: 1,
        pageSize: 100,
        _fresh: Date.now()
      }
    })
    interactiveQuestionBank.value = (pick(bank, 'items', 'Items') || []).map((row) => ({
      id: Number(pick(row, 'Id', 'id')),
      text: pick(row, 'QuestionText', 'questionText') || '',
      type: pick(row, 'QuestionType', 'questionType') || '',
      score: Number(pick(row, 'DefaultScore', 'defaultScore') || 10)
    }))
    interactiveQuestionTotal.value = Number(pick(bank, 'total', 'Total') || interactiveQuestionBank.value.length)
  } catch (error) {
    interactiveQuestionBank.value = []
    interactiveQuestionTotal.value = 0
    show(error.message, 'danger')
  } finally {
    interactiveQuestionLoading.value = false
  }
}
async function saveInteractiveEditor(lessonId) {
  await axiosClient.put(`/lessons/${lessonId}/interactive-content/settings`, {
    completionRule: lessonForm.interactiveCompletionRule,
    requireReading: lessonForm.interactiveRequireReading,
    passingScore: Number(lessonForm.interactivePassingScore) || 0,
    showResultImmediately: lessonForm.interactiveShowResult,
    showScore: lessonForm.interactiveShowScore
  })
  const activeIds = lessonForm.interactiveMappings.map((item) => item.id).filter(Boolean)
  for (const id of interactiveOriginalIds.value.filter((id) => !activeIds.includes(id)))
    await axiosClient.delete(`/content-interactions/${id}`)
  for (let index = 0; index < lessonForm.interactiveMappings.length; index += 1) {
    const mapping = lessonForm.interactiveMappings[index]
    const body = {
      questionId: mapping.questionId,
      contentAnchor: null,
      required: mapping.required,
      allowRetry: mapping.allowRetry,
      score: Number(mapping.score) || 0,
      attemptLimit: mapping.allowRetry ? Math.max(1, Number(mapping.attemptLimit) || 1) : 1,
      sortOrder: index + 1,
      status: 'ACTIVE'
    }
    if (mapping.id) await axiosClient.put(`/content-interactions/${mapping.id}`, body)
    else await axiosClient.post(`/lessons/${lessonId}/content-interactions`, body)
  }
}
function isInteractiveQuestionSelected(questionId) {
  return lessonForm.interactiveMappings.some((item) => item.questionId === questionId)
}
function toggleInteractiveQuestion(question, checked) {
  if (checked && !isInteractiveQuestionSelected(question.id))
    lessonForm.interactiveMappings.push({
      id: 0,
      questionId: question.id,
      questionText: question.text,
      questionType: question.type,
      required: true,
      allowRetry: true,
      score: question.score,
      attemptLimit: 2,
      sortOrder: lessonForm.interactiveMappings.length + 1,
      status: 'ACTIVE',
      options: []
    })
  if (!checked)
    lessonForm.interactiveMappings = lessonForm.interactiveMappings.filter((item) => item.questionId !== question.id)
}
function removeInteractiveMapping(index) {
  lessonForm.interactiveMappings.splice(index, 1)
}
function moveInteractiveMapping(index, direction) {
  const targetIndex = index + direction
  if (targetIndex < 0 || targetIndex >= lessonForm.interactiveMappings.length) return
  const [mapping] = lessonForm.interactiveMappings.splice(index, 1)
  lessonForm.interactiveMappings.splice(targetIndex, 0, mapping)
}
function openQuickQuestion() {
  Object.assign(quickQuestion, blankQuickQuestion())
  quickQuestionModal.value = true
}
function parseQuestionOptions(value) {
  const rows = typeof value === 'string' ? JSON.parse(value || '[]') : value || []
  return rows.map((row) => ({
    code: pick(row, 'OptionCode', 'optionCode') || '',
    text: pick(row, 'OptionText', 'optionText') || ''
  }))
}
function normalizeQuickQuestion() {
  if (quickQuestion.questionType === 'TRUE_FALSE')
    quickQuestion.options = [
      { optionCode: 'A', optionText: 'Đúng', isCorrect: true },
      { optionCode: 'B', optionText: 'Sai', isCorrect: false }
    ]
  else if (quickQuestion.questionType !== 'SHORT_ANSWER' && quickQuestion.options.length < 2)
    quickQuestion.options = blankQuickQuestion().options
}
function selectQuickCorrect(index) {
  if (quickQuestion.questionType !== 'MULTIPLE_CHOICE')
    quickQuestion.options.forEach((option, optionIndex) => (option.isCorrect = optionIndex === index))
}
function addQuickOption() {
  quickQuestion.options.push({
    optionCode: String.fromCharCode(65 + quickQuestion.options.length),
    optionText: '',
    isCorrect: false
  })
}
async function saveQuickQuestion() {
  saving.value = true
  try {
    const isShortAnswer = quickQuestion.questionType === 'SHORT_ANSWER'
    const result = await axiosClient.post('/questions', {
      questionType: quickQuestion.questionType,
      questionText: quickQuestion.questionText,
      description: null,
      explanation: quickQuestion.explanation || null,
      difficulty: 'MEDIUM',
      defaultScore: Number(quickQuestion.defaultScore) || 0,
      shortAnswerMode: isShortAnswer ? 'EXACT_MATCH' : null,
      status: 'ACTIVE',
      options: isShortAnswer ? [] : quickQuestion.options.map((option, index) => ({ ...option, sortOrder: index + 1 })),
      answerKeys: isShortAnswer ? [{ answerText: quickQuestion.shortAnswer, isCaseSensitive: false, sortOrder: 1 }] : []
    })
    const existingMappings = [...lessonForm.interactiveMappings]
    await loadInteractiveEditor(0)
    lessonForm.interactiveMappings = existingMappings
    const questionId = Number(pick(result, 'id', 'Id'))
    const created = interactiveQuestionBank.value.find((item) => item.id === questionId)
    if (created) toggleInteractiveQuestion(created, true)
    quickQuestionModal.value = false
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
function selectLessonFile(event) {
  lessonFile.value = event.target.files?.[0] || null
}
function syncEditor(event) {
  lessonForm.contentHtml = event.currentTarget.innerHTML
}
function formatEditor(command, value = null) {
  lessonEditor.value?.focus()
  document.execCommand(command, false, value)
  lessonForm.contentHtml = lessonEditor.value?.innerHTML || ''
}
function toLocalDateTime(value) {
  if (!value) return ''
  const date = new Date(value)
  const offset = date.getTimezoneOffset() * 60000
  return new Date(date.getTime() - offset).toISOString().slice(0, 16)
}
function show(text, type = 'success') {
  message.value = text
  messageType.value = type
  window.scrollTo({ top: 0, behavior: 'smooth' })
}
</script>

<style scoped src="../../assets/css/pages/cms/content-builder.css"></style>
