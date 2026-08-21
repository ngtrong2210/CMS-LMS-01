<template>
  <section :class="['lesson-player-page', { 'focus-mode': focusMode, 'video-lesson': isVideoLesson }]">
    <header class="lesson-player-header">
      <RouterLink class="lesson-back-link" :to="`/lms/courses/${course.id || route.params.courseId}`">
        <i class="bi bi-arrow-left"></i><span>Trở về môn học</span>
      </RouterLink>
      <div class="lesson-header-context">
        <span>{{ course.title || 'Môn học' }}</span>
        <div>
          <span class="course-progress-track"><i :style="{ width: `${courseProgress}%` }"></i></span>
          <small>{{ completedLessons }}/{{ lessonCount }} bài · {{ courseProgress }}%</small>
        </div>
      </div>
      <div class="lesson-header-actions">
        <span title="Tổng thời gian học trong môn học">
          <i class="bi bi-clock"></i> {{ formatStudyTime(studySeconds) }}
        </span>
        <button
          type="button"
          :title="focusMode ? 'Thoát chế độ tập trung' : 'Chế độ tập trung'"
          @click="focusMode = !focusMode"
        >
          <i :class="['bi', focusMode ? 'bi-fullscreen-exit' : 'bi-arrows-fullscreen']"></i>
        </button>
        <button type="button" title="Ẩn hoặc hiện nội dung môn học" @click="sidebarOpen = !sidebarOpen">
          <i class="bi bi-layout-sidebar-reverse"></i>
        </button>
      </div>
    </header>
    <div v-if="loading" class="app-card p-5 text-center">
      <span class="spinner-border text-success"></span>
      <p class="text-secondary mt-3 mb-0">Đang tải bài học...</p>
    </div>
    <div v-else-if="error" class="app-card p-5 text-center">
      <i class="bi bi-exclamation-circle fs-1 text-danger"></i>
      <h1 class="h4 mt-3">Không thể mở bài học</h1>
      <p class="text-secondary">{{ error }}</p>
      <button class="btn btn-action-refresh" @click="loadPlayer()">
        <i class="bi bi-arrow-clockwise"></i> Thử lại
      </button>
    </div>
    <template v-else>
      <div :class="['player-grid', { 'sidebar-closed': !sidebarOpen || focusMode }]">
        <div class="video-area">
          <Transition name="lesson-switch">
            <div v-if="switchingLesson" class="lesson-switch-overlay" role="status" aria-live="polite">
              <span class="spinner-border"></span>
              <strong>Đang chuyển bài học...</strong>
              <small>Đang tải nội dung tiếp theo</small>
            </div>
          </Transition>
          <div :class="['current-lesson-heading', `${lessonTypeClass(lesson.type)}-surface`]">
            <span :class="['lesson-type-icon', lessonTypeClass(lesson.type)]">
              <i :class="['bi', lessonTypeMeta(lesson.type).icon]"></i>
            </span>
            <div>
              <small>{{ lessonTypeMeta(lesson.type).label }}</small>
              <h1>{{ lesson.title }}</h1>
            </div>
            <span v-if="isVideoLesson" class="lesson-watch-status"
              >Đã xem {{ Math.round(progress.watchPercent) }}%</span
            >
          </div>
          <div class="video-stage">
            <InteractiveVideoPlayer
              v-if="isVideoLesson"
              ref="playerRef"
              :key="playerKey"
              :source="video.url"
              :source-type="video.sourceType"
              :poster="video.poster"
              :duration-seconds="video.duration"
              :interactions="interactions"
              :answered-interaction-ids="answeredInteractionIds"
              :allow-seek="video.allowSeek"
              :allow-speed="video.allowSpeed"
              :initial-time="progress.currentTime"
              :max-watched-time="progress.maxWatchedTime"
              :reset-key="playerKey"
              :on-submit-answer="submitInteractionAnswer"
              @progress="handleProgress"
              @answered="handleAnswered"
            />
            <InteractiveContentViewer
              v-else-if="lesson.type === 'INTERACTIVE_CONTENT'"
              :lesson-id="lesson.id"
              @score-change="currentScore = $event"
              @completed="handleInteractiveCompleted"
            />
            <article
              v-else-if="['EDITOR', 'DOCUMENT'].includes(lesson.type)"
              class="learning-content editor-content document-content"
            >
              <div v-if="lesson.contentHtml" class="lesson-html" v-html="sanitizedContentHtml"></div>
              <section v-if="lesson.documentUrl" :class="{ 'combined-lesson-document': lesson.contentHtml }">
                <div class="document-heading">
                  <span class="content-type-icon"><i class="bi bi-paperclip"></i></span>
                  <div>
                    <h2>Tài liệu đính kèm</h2>
                    <p>Đọc trực tiếp trên hệ thống hoặc mở file toàn màn hình.</p>
                  </div>
                  <div class="document-actions">
                    <a class="btn btn-action-view" :href="documentAssetUrl" target="_blank" rel="noopener">
                      <i class="bi bi-arrows-fullscreen"></i> Mở toàn màn hình
                    </a>
                    <a class="btn btn-action-save" :href="documentAssetUrl" target="_blank" rel="noopener" download>
                      <i class="bi bi-download"></i> Tải tài liệu
                    </a>
                  </div>
                </div>
                <div class="document-viewer">
                  <iframe
                    v-if="isPdfDocument"
                    :src="documentAssetUrl"
                    :title="`Tài liệu ${lesson.title}`"
                    loading="eager"
                  ></iframe>
                  <div v-else-if="isDocxDocument" class="docx-preview-shell">
                    <div v-if="documentPreviewLoading" class="document-preview-status">
                      <span class="spinner-border spinner-border-sm"></span> Đang mở nội dung Word...
                    </div>
                    <article
                      v-else-if="documentPreviewHtml"
                      class="docx-preview-content"
                      v-html="sanitizedDocumentPreviewHtml"
                    ></article>
                    <div v-else class="document-file-card">
                      <i class="bi bi-file-earmark-word"></i>
                      <strong>Không thể hiển thị nội dung Word</strong>
                      <span>{{ documentPreviewError || 'Bạn vẫn có thể mở hoặc tải file gốc.' }}</span>
                    </div>
                  </div>
                  <div v-else class="document-file-card">
                    <i class="bi bi-file-earmark-arrow-down"></i>
                    <strong>{{ documentFileName }}</strong>
                    <span>Định dạng này cần mở bằng ứng dụng phù hợp trên thiết bị.</span>
                  </div>
                </div>
              </section>
              <div v-if="!lesson.contentHtml && !lesson.documentUrl" class="document-empty">
                <i class="bi bi-file-earmark-x"></i>
                <strong>Bài học chưa có nội dung</strong>
                <span>Giảng viên chưa soạn nội dung hoặc cập nhật tài liệu cho bài học này.</span>
              </div>
            </article>
            <article v-else-if="lesson.type === 'ASSIGNMENT'" class="learning-content assignment-content">
              <div class="assignment-heading">
                <span class="content-type-icon"><i class="bi bi-clipboard-check-fill"></i></span>
                <div>
                  <small>Bài tập cần nộp</small>
                  <h2>{{ lesson.title }}</h2>
                  <p v-if="lesson.dueAt" class="assignment-deadline">
                    <i class="bi bi-calendar2-event-fill"></i>
                    <span>Hạn nộp: {{ dateTimeText(lesson.dueAt) }}</span>
                  </p>
                  <p v-else class="assignment-deadline assignment-deadline-open">
                    <i class="bi bi-infinity"></i>
                    <span>Không giới hạn thời gian nộp</span>
                  </p>
                </div>
                <div class="assignment-metadata">
                  <span><i class="bi bi-star-fill"></i> {{ lesson.assignmentMaxScore }} điểm</span>
                  <span><i class="bi bi-arrow-repeat"></i> {{ lesson.maxSubmissionAttempts }} lần nộp</span>
                  <span :class="assignmentAvailability ? 'closed' : 'open'">
                    <i class="bi bi-circle-fill"></i> {{ assignmentAvailability ? 'Đang đóng' : 'Đang nhận bài' }}
                  </span>
                </div>
              </div>
              <section class="assignment-requirements">
                <h3><i class="bi bi-list-check"></i> Yêu cầu bài tập</h3>
                <div v-if="lesson.contentHtml" class="lesson-html" v-html="sanitizedContentHtml"></div>
                <p v-else>{{ lesson.description || 'Thực hiện yêu cầu và nộp bài tại biểu mẫu bên dưới.' }}</p>
                <a
                  v-if="lesson.documentUrl"
                  class="assignment-resource"
                  :href="resolveApiAssetUrl(lesson.documentUrl)"
                  target="_blank"
                  rel="noopener"
                  ><i class="bi bi-file-earmark-arrow-down-fill"></i
                  ><span
                    ><strong>{{ documentFileName }}</strong
                    ><small>Mở hoặc tải đề bài đính kèm</small></span
                  ></a
                >
                <div v-if="lesson.documentUrl" class="assignment-document-preview">
                  <div class="document-preview-heading">
                    <div>
                      <i class="bi bi-eye-fill"></i>
                      <strong>Nội dung đề bài</strong>
                    </div>
                    <small>{{ isPdfDocument ? 'PDF' : isDocxDocument ? 'DOCX' : 'Tệp đính kèm' }}</small>
                  </div>
                  <iframe
                    v-if="isPdfDocument"
                    :src="documentAssetUrl"
                    :title="`Đề bài ${lesson.title}`"
                    loading="eager"
                  ></iframe>
                  <div v-else-if="isDocxDocument" class="docx-preview-shell">
                    <div v-if="documentPreviewLoading" class="document-preview-status">
                      <span class="spinner-border spinner-border-sm"></span> Đang mở nội dung Word...
                    </div>
                    <article
                      v-else-if="documentPreviewHtml"
                      class="docx-preview-content"
                      v-html="sanitizedDocumentPreviewHtml"
                    ></article>
                    <div v-else class="document-file-card compact">
                      <i class="bi bi-file-earmark-word"></i>
                      <strong>Không thể hiển thị nội dung Word</strong>
                      <span>{{ documentPreviewError || 'Bạn vẫn có thể mở hoặc tải file gốc ở phía trên.' }}</span>
                    </div>
                  </div>
                  <div v-else class="document-file-card compact">
                    <i class="bi bi-file-earmark-arrow-down"></i>
                    <strong>Định dạng này chưa hỗ trợ xem trực tiếp</strong>
                    <span>Hãy dùng liên kết phía trên để mở hoặc tải tài liệu.</span>
                  </div>
                </div>
              </section>
              <div v-if="assignmentAvailability" class="assignment-availability">
                <i class="bi bi-info-circle"></i> {{ assignmentAvailability }}
              </div>
              <form v-else class="assignment-form" @submit.prevent="showSubmitConfirm = true">
                <div class="submission-heading">
                  <div>
                    <small>{{ isEditingSubmitted ? 'CHỈNH SỬA BÀI ĐÃ NỘP' : 'NỘP BÀI' }}</small>
                    <h3>
                      {{ isEditingSubmitted ? 'Cập nhật bài làm trước hạn nộp' : 'Chọn cách hoàn thành bài tập' }}
                    </h3>
                  </div>
                  <span v-if="isEditingSubmitted">Lần {{ editableSubmission.attemptNumber }}</span>
                  <span v-else>{{ lesson.maxSubmissionAttempts }} lần nộp tối đa</span>
                </div>
                <div v-if="isEditingSubmitted" class="editable-submission-notice">
                  <i class="bi bi-pencil-square"></i>
                  <span>
                    <strong>Bài đã nộp vẫn được phép chỉnh sửa</strong>
                    <small>Mọi thay đổi sẽ cập nhật vào lần nộp hiện tại và không tính thêm lượt.</small>
                  </span>
                </div>
                <div class="submission-mode-switch" role="group" aria-label="Cách nộp bài">
                  <button
                    type="button"
                    :class="{ active: submissionMode === 'editor' }"
                    @click="submissionMode = 'editor'"
                  >
                    <i class="bi bi-pencil-square"></i
                    ><span><strong>Soạn trực tuyến</strong><small>Nhập bài làm ngay trên hệ thống</small></span>
                  </button>
                  <button type="button" :class="{ active: submissionMode === 'file' }" @click="submissionMode = 'file'">
                    <i class="bi bi-cloud-arrow-up"></i
                    ><span><strong>Tải file bài làm</strong><small>PDF, Word, Excel, ZIP hoặc ảnh</small></span>
                  </button>
                </div>
                <label v-if="submissionMode === 'editor'" class="submission-editor">
                  <span>Nội dung bài làm</span>
                  <textarea
                    v-model.trim="submissionText"
                    class="form-control"
                    rows="7"
                    placeholder="Nhập nội dung bài làm của bạn tại đây..."
                  ></textarea>
                </label>
                <label v-else class="submission-upload">
                  <input
                    class="visually-hidden"
                    type="file"
                    accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.zip,.txt,.png,.jpg,.jpeg"
                    @change="selectSubmissionFile"
                  />
                  <i class="bi bi-cloud-arrow-up"></i>
                  <strong>{{ submissionFile?.name || 'Chọn file bài làm' }}</strong>
                  <span>Kéo thả hoặc bấm để chọn file · tối đa {{ lesson.maxSubmissionFileSizeMB }} MB</span>
                </label>
                <a
                  v-if="submissionMode === 'file' && editableSubmission?.fileUrl && !submissionFile"
                  class="current-submission-file"
                  :href="resolveApiAssetUrl(editableSubmission.fileUrl)"
                  target="_blank"
                  rel="noopener"
                >
                  <i class="bi bi-file-earmark-check-fill"></i>
                  <span
                    ><strong>{{ editableSubmission.fileName }}</strong
                    ><small>File đang được lưu trong bài đã nộp</small></span
                  >
                  <i class="bi bi-box-arrow-up-right"></i>
                </a>
                <button
                  v-if="submissionMode === 'file' && submissionFile"
                  type="button"
                  class="remove-submission-file"
                  @click="submissionFile = null"
                >
                  <i class="bi bi-x-circle"></i> Bỏ file {{ submissionFile.name }}
                </button>
                <div v-if="assignmentMessage" class="assignment-success">
                  <i class="bi bi-check-circle-fill"></i> {{ assignmentMessage }}
                </div>
                <div v-if="assignmentError" class="assignment-error">
                  <i class="bi bi-exclamation-circle-fill"></i> {{ assignmentError }}
                </div>
                <div class="assignment-actions">
                  <button
                    type="button"
                    class="btn btn-action-view"
                    :disabled="submitting || !canSubmitAssignment"
                    @click="saveAssignmentDraft"
                  >
                    <i class="bi bi-floppy"></i> Lưu nháp</button
                  ><button class="btn btn-action-save assignment-submit" :disabled="submitting || !canSubmitAssignment">
                    <span v-if="submitting" class="spinner-border spinner-border-sm"></span
                    ><i v-else class="bi bi-send-check"></i>
                    {{ isEditingSubmitted ? 'Cập nhật bài đã nộp' : 'Nộp bài ngay' }}
                  </button>
                </div>
              </form>
              <div v-if="submissions.length" class="submission-history">
                <h3>Lịch sử nộp bài</h3>
                <div v-for="item in submissions" :key="item.id" class="submission-history-item">
                  <div class="submission-record-main">
                    <span class="attempt">Lần {{ item.attemptNumber }}</span>
                    <div>
                      <strong>{{ submissionStatus(item.status) }}</strong
                      ><small>{{ dateTimeText(item.submittedAt) }}</small
                      ><small v-if="item.feedback" class="teacher-feedback">Nhận xét: {{ item.feedback }}</small>
                    </div>
                    <button
                      v-if="canEditSubmission(item)"
                      type="button"
                      class="edit-submission-button"
                      @click="editSubmission(item)"
                    >
                      <i class="bi bi-pencil-square"></i> Sửa bài
                    </button>
                    <span v-if="item.score != null" class="submission-score"
                      >{{ item.score }}/{{ lesson.assignmentMaxScore }} điểm</span
                    >
                  </div>
                  <details class="submission-detail">
                    <summary><i class="bi bi-eye"></i> Xem nội dung bài đã nộp</summary>
                    <div class="submission-detail-content">
                      <div v-if="item.submissionText" class="submitted-text">
                        <strong>Nội dung soạn trực tuyến</strong>
                        <p>{{ item.submissionText }}</p>
                      </div>
                      <a
                        v-if="item.fileUrl"
                        class="submitted-file"
                        :href="resolveApiAssetUrl(item.fileUrl)"
                        target="_blank"
                        rel="noopener"
                      >
                        <i class="bi bi-file-earmark-arrow-down-fill"></i>
                        <span
                          ><strong>{{ item.fileName }}</strong
                          ><small>Mở hoặc tải file bài làm</small></span
                        >
                      </a>
                      <p v-if="!item.submissionText && !item.fileUrl" class="submission-detail-empty">
                        Bài nộp này không có nội dung hoặc file đính kèm.
                      </p>
                    </div>
                  </details>
                </div>
              </div>
            </article>
            <article v-else-if="lesson.type === 'QUIZ'" class="learning-content quiz-content">
              <div class="content-type-icon"><i class="bi bi-ui-checks"></i></div>
              <h2>{{ quiz.title || lesson.title }}</h2>
              <p>{{ quiz.description || 'Hoàn thành các câu hỏi và nộp bài để nhận kết quả.' }}</p>
              <div class="quiz-summary">
                <span><i class="bi bi-patch-question"></i> {{ quizQuestions.length }} câu</span>
                <span
                  v-if="quizAttemptId && quiz.timeLimitMinutes"
                  :class="['quiz-countdown', { 'is-urgent': quizSecondsRemaining <= 60 }]"
                >
                  <i class="bi bi-hourglass-split"></i> Còn lại {{ quizCountdownText }}
                </span>
                <span v-else
                  ><i class="bi bi-clock"></i>
                  {{ quiz.timeLimitMinutes ? `${quiz.timeLimitMinutes} phút` : 'Không giới hạn' }}</span
                >
                <span><i class="bi bi-arrow-repeat"></i> {{ quiz.attemptCount }}/{{ quiz.maxAttempts }} lượt</span>
                <span><i class="bi bi-bullseye"></i> Đạt từ {{ quiz.passingScore }}%</span>
              </div>
              <button
                v-if="!quizAttemptId"
                class="btn btn-action-save"
                :disabled="quiz.attemptCount >= quiz.maxAttempts || quizBusy"
                @click="startQuiz"
              >
                <i class="bi bi-play-fill"></i> Bắt đầu làm bài
              </button>
              <form v-else class="quiz-form" @submit.prevent="submitQuiz">
                <div v-if="quiz.timeLimitMinutes" class="quiz-timer-notice">
                  <i class="bi bi-shield-check"></i>
                  <span>
                    <strong>Bài làm sẽ tự động được nộp khi hết giờ</strong>
                    <small>Đáp án đã chọn tại thời điểm đồng hồ về 00:00 sẽ được gửi để chấm điểm.</small>
                  </span>
                </div>
                <fieldset
                  v-for="(question, questionIndex) in quizQuestions"
                  :key="question.id"
                  class="quiz-question-card"
                  :disabled="quizBusy"
                >
                  <legend>Câu {{ questionIndex + 1 }} · {{ question.score }} điểm</legend>
                  <p>{{ question.text }}</p>
                  <template v-if="question.type === 'MULTIPLE_CHOICE'">
                    <label v-for="option in question.options" :key="option.code" class="quiz-option">
                      <input v-model="quizAnswers[question.id]" :value="option.code" type="checkbox" />
                      {{ option.text }}
                    </label>
                  </template>
                  <template v-else-if="['SINGLE_CHOICE', 'TRUE_FALSE'].includes(question.type)">
                    <label v-for="option in question.options" :key="option.code" class="quiz-option">
                      <input
                        v-model="quizAnswers[question.id]"
                        :value="option.code"
                        type="radio"
                        :name="`quiz-${question.id}`"
                      />
                      {{ option.text }}
                    </label>
                  </template>
                  <textarea
                    v-else
                    v-model.trim="quizAnswers[question.id]"
                    class="form-control"
                    rows="3"
                    placeholder="Nhập câu trả lời..."
                  ></textarea>
                </fieldset>
                <button class="btn btn-action-save" :disabled="quizBusy">
                  <i class="bi bi-send-check"></i> Nộp bài kiểm tra
                </button>
              </form>
              <div v-if="quizAutoSubmitNotice" class="quiz-auto-submit-notice">
                <i class="bi bi-clock-history"></i> {{ quizAutoSubmitNotice }}
              </div>
              <div v-if="quizResult" :class="['quiz-result', quizResult.passed ? 'passed' : 'failed']">
                <i :class="['bi', quizResult.passed ? 'bi-check-circle-fill' : 'bi-x-circle-fill']"></i>
                <strong>{{ quizResult.scorePercent }}% · {{ quizResult.passed ? 'Đạt' : 'Chưa đạt' }}</strong>
                <span>{{ quizResult.score }}/{{ quizResult.maxScore }} điểm</span>
              </div>
              <div v-if="quizAttempts.length" class="submission-history quiz-history">
                <h3>Lịch sử làm bài</h3>
                <div v-for="attempt in quizAttempts" :key="attempt.id">
                  <span class="attempt">Lần {{ attempt.number }}</span>
                  <div>
                    <strong>{{ attempt.status === 'SUBMITTED' ? `${attempt.scorePercent}%` : 'Đang làm' }}</strong
                    ><small>{{ dateTimeText(attempt.submittedAt || attempt.startedAt) }}</small>
                  </div>
                  <span
                    v-if="attempt.passed != null"
                    :class="['submission-score', attempt.passed ? 'text-success' : 'text-danger']"
                    >{{ attempt.passed ? 'Đạt' : 'Chưa đạt' }}</span
                  >
                </div>
              </div>
            </article>
            <article v-else class="learning-content document-content">
              <div class="content-type-icon"><i class="bi bi-info-circle"></i></div>
              <h2>Nội dung bài học</h2>
              <p>Loại bài học này chưa có nội dung phù hợp.</p>
            </article>
          </div>
          <div class="lesson-meta">
            <div>
              <p>{{ lesson.description || 'Học qua video và hoàn thành các câu hỏi tương tác.' }}</p>
            </div>
            <div class="score">
              <strong>{{ currentScore }}</strong
              ><small>Điểm hiện tại</small>
            </div>
          </div>
        </div>
        <div class="lesson-support-column">
          <nav class="lesson-tabs" aria-label="Nội dung bổ sung của bài học">
            <button
              v-for="tab in lessonTabs"
              :key="tab.key"
              type="button"
              :class="{ active: activeTab === tab.key }"
              @click="activeTab = tab.key"
            >
              <i :class="['bi', tab.icon]"></i> {{ tab.label }}
              <span v-if="tab.key === 'discussion' && discussionCount">{{ discussionCount }}</span>
            </button>
          </nav>
          <div v-if="activeTab === 'overview'">
            <div v-if="isVideoLesson" class="app-card p-4 mt-4">
              <h2 class="h5 fw-bold">Mốc câu hỏi tương tác</h2>
              <div v-if="interactions.length" class="interaction-list">
                <button
                  v-for="item in interactions"
                  :key="item.id"
                  type="button"
                  :class="{ answered: item.answered }"
                  @click="playerRef?.openQuestion(item)"
                >
                  <span>{{ formatTime(item.timeSeconds) }}</span
                  ><i :class="['bi', item.answered ? 'bi-check-circle-fill' : 'bi-patch-question']"></i>
                  <div>
                    <strong>{{ item.label }}</strong
                    ><small>{{ questionTypeLabel(item.type) }} • {{ item.score }} điểm</small>
                  </div>
                </button>
              </div>
              <p v-else class="text-secondary mb-0">Bài học này không có câu hỏi tương tác.</p>
            </div>
            <div
              v-if="!isVideoLesson && !['ASSIGNMENT', 'INTERACTIVE_CONTENT'].includes(lesson.type)"
              class="lesson-completion app-card mt-4"
            >
              <div>
                <strong>Hoàn thành nội dung này?</strong
                ><small>Hệ thống chỉ ghi nhận thời gian hợp lệ từ heartbeat khi trang đang hoạt động.</small>
              </div>
              <button class="btn btn-action-save" :disabled="completing" @click="markLessonComplete">
                <span v-if="completing" class="spinner-border spinner-border-sm"></span
                ><i v-else class="bi bi-check2-circle"></i> Đánh dấu hoàn thành
              </button>
            </div>
          </div>
          <section v-else-if="activeTab === 'resources'" class="lesson-resource-tab app-card">
            <div v-if="lesson.documentUrl" class="resource-list-item">
              <span :class="['lesson-type-icon', lessonTypeClass('DOCUMENT')]"
                ><i class="bi bi-file-earmark-pdf-fill"></i
              ></span>
              <div>
                <strong>{{ documentFileName }}</strong
                ><small>Tài liệu đính kèm của bài học</small>
              </div>
              <a :href="documentAssetUrl" target="_blank" rel="noopener"><i class="bi bi-download"></i> Tải xuống</a>
            </div>
            <div v-else class="discussion-empty">
              <i class="bi bi-folder2-open"></i><strong>Chưa có tài nguyên đính kèm</strong>
            </div>
          </section>
          <LessonDiscussion
            v-else-if="activeTab === 'discussion'"
            :lesson-id="lesson.id"
            @count-change="discussionCount = $event"
          />

          <nav class="lesson-navigation" aria-label="Điều hướng bài học">
            <RouterLink v-if="previousLesson" :to="lessonUrl(previousLesson)" class="previous">
              <i class="bi bi-arrow-left"></i>
              <span
                ><small>Bài trước</small><strong>{{ previousLesson.title }}</strong></span
              >
            </RouterLink>
            <span v-else></span>
            <RouterLink v-if="nextLesson" :to="lessonUrl(nextLesson)" class="next">
              <span
                ><small>Bài tiếp theo</small><strong>{{ nextLesson.title }}</strong></span
              >
              <i class="bi bi-arrow-right"></i>
            </RouterLink>
          </nav>
        </div>
        <button
          v-if="sidebarOpen && !focusMode"
          type="button"
          class="curriculum-backdrop"
          aria-label="Đóng nội dung môn học"
          @click="sidebarOpen = false"
        ></button>
        <aside v-show="sidebarOpen && !focusMode" class="content-panel">
          <div class="curriculum-heading">
            <div>
              <strong>Nội dung môn học</strong><small>{{ completedLessons }}/{{ lessonCount }} bài đã hoàn thành</small>
            </div>
            <button type="button" title="Đóng danh sách" @click="sidebarOpen = false">
              <i class="bi bi-x-lg"></i>
            </button>
          </div>
          <div class="chapter-list">
            <div v-for="chapter in chapters" :key="chapter.id" class="chapter">
              <button type="button" class="chapter-toggle" @click="toggleChapter(chapter.id)">
                <span
                  ><strong>{{ chapter.title }}</strong
                  ><small>{{ chapter.lessons.length }} bài học</small></span
                >
                <i :class="['bi', expandedChapters.has(chapter.id) ? 'bi-chevron-up' : 'bi-chevron-down']"></i>
              </button>
              <div v-show="expandedChapters.has(chapter.id)" class="chapter-lessons">
                <RouterLink
                  v-for="item in chapter.lessons"
                  :key="item.id"
                  :to="`/lms/courses/${course.id}/lessons/${item.id}`"
                  :class="{ active: item.id === lesson.id }"
                >
                  <span :class="['lesson-type-icon', lessonTypeClass(item.type)]">
                    <i :class="['bi', lessonTypeMeta(item.type).icon]"></i>
                  </span>
                  <span
                    ><strong>{{ item.title }}</strong
                    ><small>{{ lessonTypeMeta(item.type).label }} · {{ formatTime(item.duration) }}</small></span
                  >
                  <i
                    v-if="item.completed"
                    class="bi bi-check-circle-fill lesson-status-complete"
                    title="Đã hoàn thành"
                  ></i>
                  <i
                    v-else-if="item.id === lesson.id"
                    class="bi bi-play-circle-fill lesson-status-current"
                    title="Đang học"
                  ></i>
                </RouterLink>
              </div>
            </div>
          </div>
        </aside>
      </div>

      <div v-if="showSubmitConfirm" class="app-modal-backdrop" @click.self="showSubmitConfirm = false">
        <div
          class="app-confirm-modal assignment-confirm"
          role="dialog"
          aria-modal="true"
          aria-labelledby="submit-assignment-title"
        >
          <span class="confirm-icon"><i class="bi bi-send-check-fill"></i></span>
          <small>{{ isEditingSubmitted ? 'XÁC NHẬN CẬP NHẬT' : 'XÁC NHẬN NỘP BÀI' }}</small>
          <h3 id="submit-assignment-title">Bạn đã kiểm tra bài làm?</h3>
          <p v-if="isEditingSubmitted">
            Nội dung mới sẽ thay thế bài đã nộp trong cùng lượt hiện tại và được gửi lại đến giảng viên.
          </p>
          <p v-else>Sau khi nộp, bài làm được ghi nhận là một lượt nộp chính thức và gửi đến giảng viên.</p>
          <dl>
            <div>
              <dt>Hình thức</dt>
              <dd>{{ submissionMode === 'file' ? 'Tải file' : 'Soạn trực tuyến' }}</dd>
            </div>
            <div v-if="submissionFile">
              <dt>Tệp</dt>
              <dd>{{ submissionFile.name }}</dd>
            </div>
          </dl>
          <div>
            <button type="button" class="btn-comment-plain" @click="showSubmitConfirm = false">Kiểm tra lại</button>
            <button type="button" class="btn-comment-primary" @click="confirmSubmitAssignment">
              <i class="bi bi-send-fill"></i> {{ isEditingSubmitted ? 'Xác nhận cập nhật' : 'Xác nhận nộp' }}
            </button>
          </div>
        </div>
      </div>
    </template>
  </section>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import { resolveApiAssetUrl } from '../../api/apiConfig'
import { questionTypeLabel } from '../../utils/displayLabels'
import { formatInteractionTime } from '../../utils/learningRules'
import InteractiveVideoPlayer from '../../components/video/InteractiveVideoPlayer.vue'
import InteractiveContentViewer from '../../components/learning/InteractiveContentViewer.vue'
import LessonDiscussion from '../../components/learning/LessonDiscussion.vue'
import { normalizeVideoSource } from '../../utils/videoSources'
import { sanitizeLearningHtml } from '../../utils/sanitizeHtml'
import { lessonTypeClass, lessonTypeMeta } from '../../utils/lessonTypes'

const route = useRoute(),
  playerRef = ref(null),
  loading = ref(true),
  switchingLesson = ref(false),
  error = ref(''),
  interactions = ref([]),
  chapters = ref([]),
  answeredInteractionIds = ref([]),
  playerKey = ref(0),
  studySessionId = ref(''),
  studySeconds = ref(0),
  studySessionSeconds = ref(0),
  submissions = ref([]),
  submissionText = ref(''),
  submissionFile = ref(null),
  submissionMode = ref('editor'),
  assignmentMessage = ref(''),
  assignmentError = ref(''),
  submitting = ref(false),
  completing = ref(false),
  sidebarOpen = ref(true),
  focusMode = ref(false),
  activeTab = ref('overview'),
  showSubmitConfirm = ref(false),
  discussionCount = ref(0),
  documentPreviewHtml = ref(''),
  documentPreviewLoading = ref(false),
  documentPreviewError = ref(''),
  loadedCourseContentId = ref(0),
  expandedChapters = ref(new Set())
const quiz = reactive({
  id: 0,
  title: '',
  description: '',
  passingScore: 50,
  timeLimitMinutes: null,
  maxAttempts: 1,
  attemptCount: 0
})
const quizQuestions = ref([]),
  quizAttempts = ref([]),
  quizAttemptId = ref(0),
  quizSecondsRemaining = ref(0),
  quizAutoSubmitNotice = ref(''),
  quizAnswers = reactive({}),
  quizResult = ref(null),
  quizBusy = ref(false)
const lesson = reactive({
    id: 0,
    title: '',
    description: '',
    type: 'VIDEO',
    duration: 0,
    passingScore: 0,
    contentHtml: '',
    documentUrl: '',
    assignmentStartAt: null,
    dueAt: null,
    assignmentMaxScore: 100,
    maxSubmissionAttempts: 3,
    maxSubmissionFileSizeMB: 50,
    allowLateSubmission: false
  }),
  course = reactive({ id: 0, title: '' }),
  video = reactive({
    id: 0,
    sourceType: 'LOCAL',
    url: '',
    poster: '',
    duration: 0,
    allowSeek: false,
    allowSpeed: true,
    requiredWatchPercent: 80
  }),
  progress = reactive({ currentTime: 0, maxWatchedTime: 0, watchPercent: 0 })
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const formatTime = formatInteractionTime
const currentScore = ref(0),
  lastSavedAt = ref(0),
  savingProgress = ref(false)
const quizCountdownText = computed(() => {
  const seconds = Math.max(0, Number(quizSecondsRemaining.value) || 0)
  const minutes = Math.floor(seconds / 60)
  return `${String(minutes).padStart(2, '0')}:${String(seconds % 60).padStart(2, '0')}`
})
const lessonCount = computed(() => chapters.value.reduce((total, chapter) => total + chapter.lessons.length, 0)),
  isVideoLesson = computed(() => ['VIDEO', 'INTERACTIVE_VIDEO'].includes(lesson.type)),
  documentAssetUrl = computed(() => resolveApiAssetUrl(lesson.documentUrl)),
  documentFileName = computed(() => {
    const path = String(lesson.documentUrl || '').split('?')[0]
    return decodeURIComponent(path.split('/').pop() || 'Tài liệu bài học')
  }),
  isPdfDocument = computed(() => /\.pdf(?:$|[?#])/i.test(lesson.documentUrl || '')),
  isDocxDocument = computed(() => /\.docx(?:$|[?#])/i.test(lesson.documentUrl || '')),
  sanitizedDocumentPreviewHtml = computed(() => sanitizeLearningHtml(documentPreviewHtml.value)),
  latestSubmission = computed(() => submissions.value[0] || null),
  editableSubmission = computed(() => (canEditSubmission(latestSubmission.value) ? latestSubmission.value : null)),
  isEditingSubmitted = computed(() => ['SUBMITTED', 'RETURNED'].includes(editableSubmission.value?.status)),
  canSubmitAssignment = computed(() =>
    submissionMode.value === 'file' ? Boolean(submissionFile.value) : Boolean(submissionText.value.trim())
  ),
  sanitizedContentHtml = computed(() =>
    sanitizeLearningHtml(lesson.contentHtml || '<p>Bài học chưa có nội dung soạn thảo.</p>')
  ),
  assignmentAvailability = computed(() => {
    const now = Date.now()
    if (lesson.assignmentStartAt && now < new Date(lesson.assignmentStartAt).getTime())
      return `Bài tập mở lúc ${dateTimeText(lesson.assignmentStartAt)}.`
    if (latestSubmission.value?.status === 'GRADED')
      return 'Bài làm đã được giáo viên chấm. Bạn có thể xem lại nội dung nhưng không thể chỉnh sửa.'
    if (lesson.dueAt && now > new Date(lesson.dueAt).getTime() && !lesson.allowLateSubmission)
      return `Đã hết hạn nộp lúc ${dateTimeText(lesson.dueAt)}.`
    const submittedAttempts = submissions.value.filter((item) => item.status !== 'DRAFT').length
    if (!editableSubmission.value && submittedAttempts >= lesson.maxSubmissionAttempts)
      return `Bạn đã sử dụng đủ ${lesson.maxSubmissionAttempts} lần nộp.`
    return ''
  }),
  completedLessons = computed(() =>
    chapters.value.reduce((total, chapter) => total + chapter.lessons.filter((x) => x.completed).length, 0)
  ),
  courseProgress = computed(() =>
    lessonCount.value ? Math.round((completedLessons.value / lessonCount.value) * 100) : 0
  ),
  lessonTabs = computed(() => [
    {
      key: 'overview',
      label: lesson.type === 'ASSIGNMENT' ? 'Bài tập' : 'Tổng quan',
      icon: lesson.type === 'ASSIGNMENT' ? 'bi-clipboard-check' : 'bi-info-circle'
    },
    { key: 'resources', label: 'Tài nguyên', icon: 'bi-paperclip' },
    { key: 'discussion', label: 'Thảo luận', icon: 'bi-chat-square-text' }
  ]),
  orderedLessons = computed(() => chapters.value.flatMap((chapter) => chapter.lessons)),
  currentLessonIndex = computed(() => orderedLessons.value.findIndex((item) => item.id === lesson.id)),
  previousLesson = computed(() =>
    currentLessonIndex.value > 0 ? orderedLessons.value[currentLessonIndex.value - 1] : null
  ),
  nextLesson = computed(() =>
    currentLessonIndex.value >= 0 && currentLessonIndex.value < orderedLessons.value.length - 1
      ? orderedLessons.value[currentLessonIndex.value + 1]
      : null
  )
const activityEvents = ['mousemove', 'keydown', 'click', 'scroll']
let lastActivityAt = Date.now()
let quizCountdownTimer
let quizCountdownDeadline = 0
const recordActivity = () => (lastActivityAt = Date.now())
onMounted(() => {
  activityEvents.forEach((eventName) => window.addEventListener(eventName, recordActivity, { passive: true }))
  if (window.matchMedia('(max-width: 1100px)').matches) sidebarOpen.value = false
  loadPlayer()
})
onBeforeUnmount(() => {
  stopQuizCountdown()
  activityEvents.forEach((eventName) => window.removeEventListener(eventName, recordActivity))
  playerRef.value?.pause()
  void saveProgress()
  void stopStudySession(false)
})
watch(
  () => route.params.lessonId,
  () => {
    stopQuizCountdown()
    playerRef.value?.pause()
    activeTab.value = 'overview'
    showSubmitConfirm.value = false
    discussionCount.value = 0
    switchingLesson.value = true
    void Promise.allSettled([saveProgress(), stopStudySession(false)]).finally(() =>
      loadPlayer({ preserveShell: true })
    )
  }
)
async function loadPlayer({ preserveShell = false } = {}) {
  if (preserveShell) switchingLesson.value = true
  else loading.value = true
  error.value = ''
  try {
    const data = await axiosClient.get(`/lms/lessons/${Number(route.params.lessonId)}/player`, {
      params: { _fresh: Date.now() }
    })
    const l = pick(data, 'lesson', 'Lesson') || {},
      c = pick(data, 'course', 'Course') || {},
      v = pick(data, 'video', 'Video') || {},
      p = pick(data, 'progress', 'Progress') || {}
    Object.assign(lesson, {
      id: Number(pick(l, 'Id', 'id')),
      title: pick(l, 'Title', 'title') || '',
      description: pick(l, 'Description', 'description') || '',
      type: pick(l, 'LessonType', 'lessonType') || 'VIDEO',
      duration: Number(pick(l, 'DurationSeconds', 'durationSeconds') || 0),
      passingScore: Number(pick(l, 'PassingScore', 'passingScore') || 0),
      contentHtml: pick(l, 'ContentHtml', 'contentHtml') || '',
      documentUrl: pick(l, 'DocumentUrl', 'documentUrl') || '',
      assignmentStartAt: pick(l, 'AssignmentStartAt', 'assignmentStartAt') || null,
      dueAt: pick(l, 'DueAt', 'dueAt') || null,
      assignmentMaxScore: Number(pick(l, 'AssignmentMaxScore', 'assignmentMaxScore') || 100),
      maxSubmissionAttempts: Number(pick(l, 'MaxSubmissionAttempts', 'maxSubmissionAttempts') || 3),
      maxSubmissionFileSizeMB: Number(pick(l, 'MaxSubmissionFileSizeMB', 'maxSubmissionFileSizeMB') || 50),
      allowLateSubmission: Boolean(pick(l, 'AllowLateSubmission', 'allowLateSubmission'))
    })
    Object.assign(course, { id: Number(pick(c, 'Id', 'id')), title: pick(c, 'Title', 'title') || '' })
    Object.assign(video, {
      id: Number(pick(v, 'Id', 'id') || 0),
      sourceType: normalizeVideoSource(pick(v, 'SourceType', 'sourceType')),
      url:
        normalizeVideoSource(pick(v, 'SourceType', 'sourceType')) === 'YOUTUBE'
          ? pick(v, 'VideoUrl', 'videoUrl') || ''
          : resolveApiAssetUrl(pick(v, 'VideoUrl', 'videoUrl') || ''),
      poster: resolveApiAssetUrl(pick(v, 'PosterUrl', 'posterUrl') || ''),
      duration: Number(pick(v, 'DurationSeconds', 'durationSeconds') || lesson.duration),
      allowSeek: Boolean(pick(v, 'AllowSeek', 'allowSeek')),
      allowSpeed: Boolean(pick(v, 'AllowSpeed', 'allowSpeed') ?? true),
      requiredWatchPercent: Number(pick(v, 'RequiredWatchPercent', 'requiredWatchPercent') || 80)
    })
    Object.assign(progress, {
      currentTime: Number(pick(p, 'CurrentTimeSeconds', 'currentTimeSeconds') || 0),
      maxWatchedTime: Number(pick(p, 'MaxWatchedTimeSeconds', 'maxWatchedTimeSeconds') || 0),
      watchPercent: Number(pick(p, 'WatchPercent', 'watchPercent') || 0)
    })
    const answeredRows = pick(data, 'answeredInteractions', 'AnsweredInteractions') || []
    const answeredMap = new Map(answeredRows.map((row) => [Number(pick(row, 'InteractionId', 'interactionId')), row]))
    answeredInteractionIds.value = [...answeredMap.keys()]
    const rows = pick(data, 'interactions', 'Interactions') || []
    interactions.value = rows.map((row) => {
      const answered = answeredMap.get(Number(pick(row, 'Id', 'id')))
      return {
        id: Number(pick(row, 'Id', 'id')),
        questionId: Number(pick(row, 'QuestionId', 'questionId')),
        videoId: Number(pick(row, 'VideoId', 'videoId')),
        timeSeconds: Number(pick(row, 'TimeSeconds', 'timeSeconds') || 0),
        label: pick(row, 'QuestionText', 'questionText') || 'Câu hỏi',
        description: pick(row, 'Description', 'description') || '',
        type: pick(row, 'QuestionType', 'questionType') || 'SINGLE_CHOICE',
        required: Boolean(pick(row, 'Required', 'required')),
        pauseVideo: Boolean(pick(row, 'PauseVideo', 'pauseVideo')),
        allowSkip: Boolean(pick(row, 'AllowSkip', 'allowSkip')),
        score: Number(pick(row, 'Score', 'score') || 0),
        attemptLimit: Number(pick(row, 'AttemptLimit', 'attemptLimit') || 1),
        answered: Boolean(answered),
        attempts: Number(pick(answered, 'AttemptNumber', 'attemptNumber') || 0),
        options: pick(row, 'Options', 'options')
      }
    })
    currentScore.value = answeredRows.reduce(
      (sum, row) => sum + Number(pick(row, 'ScoreAwarded', 'scoreAwarded') || 0),
      0
    )
    lastSavedAt.value = progress.currentTime
    playerKey.value++
    if (course.id && loadedCourseContentId.value !== course.id) {
      const detail = await axiosClient.get(`/lms/courses/${course.id}`, { params: { _fresh: Date.now() } })
      mapCourseContent(detail)
      loadedCourseContentId.value = course.id
    }
    submissionText.value = ''
    submissionFile.value = null
    submissionMode.value = 'editor'
    assignmentMessage.value = ''
    assignmentError.value = ''
    await loadDocumentPreview()
    if (lesson.type === 'ASSIGNMENT') await loadSubmissions()
    else submissions.value = []
    if (lesson.type === 'QUIZ') await loadQuiz()
    else resetQuiz()
    await startStudySession()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
    switchingLesson.value = false
  }
}
async function loadDocumentPreview() {
  documentPreviewHtml.value = ''
  documentPreviewError.value = ''
  documentPreviewLoading.value = false
  if (!lesson.documentUrl || !isDocxDocument.value) return

  documentPreviewLoading.value = true
  try {
    const preview = await axiosClient.get(`/lms/lessons/${lesson.id}/document-preview`, {
      params: { _fresh: Date.now() }
    })
    documentPreviewHtml.value = pick(preview, 'html', 'Html') || ''
    if (!documentPreviewHtml.value) documentPreviewError.value = 'Tài liệu Word không có nội dung để hiển thị.'
  } catch (e) {
    documentPreviewError.value = e.message || 'Không thể đọc nội dung tài liệu Word.'
  } finally {
    documentPreviewLoading.value = false
  }
}
let studyTimer
async function startStudySession() {
  clearInterval(studyTimer)
  studySessionSeconds.value = 0
  const result = await axiosClient.post('/lms/study-sessions', {
    courseId: course.id,
    lessonId: lesson.id,
    pageUrl: window.location.pathname,
    clientSessionKey: window.crypto?.randomUUID?.() || String(Date.now())
  })
  studySessionId.value = pick(result, 'StudySessionID', 'studySessionID') || ''
  studySeconds.value = Number(pick(result, 'CourseActiveStudySeconds', 'courseActiveStudySeconds') || 0)
  studyTimer = setInterval(async () => {
    const isActive = document.visibilityState === 'visible' && Date.now() - lastActivityAt < 90000
    if (isActive) {
      studySessionSeconds.value += 1
      studySeconds.value += 1
    }
    if (
      isActive &&
      studySessionSeconds.value > 0 &&
      studySessionSeconds.value % 30 === 0 &&
      studySessionId.value
    ) {
      try {
        await axiosClient.put(`/lms/study-sessions/${studySessionId.value}/heartbeat`)
      } catch {
        // Phiên sẽ được kết thúc khi người học rời trang.
      }
    }
  }, 1000)
}
async function stopStudySession(isCompleted) {
  clearInterval(studyTimer)
  const id = studySessionId.value
  studySessionId.value = ''
  if (!id) return
  try {
    const result = await axiosClient.post(`/lms/study-sessions/${id}/end`, { isCompleted })
    const courseTotal = pick(result, 'CourseActiveStudySeconds', 'courseActiveStudySeconds')
    if (courseTotal !== undefined && courseTotal !== null) studySeconds.value = Number(courseTotal)
  } catch {
    // Trình duyệt có thể đang đóng nên không làm gián đoạn trải nghiệm học.
  } finally {
    studySessionSeconds.value = 0
  }
}
async function loadSubmissions() {
  const rows = await axiosClient.get(`/lms/lessons/${lesson.id}/submissions`)
  submissions.value = (rows || []).map((row) => ({
    id: Number(pick(row, 'AssignmentSubmissionID', 'assignmentSubmissionID')),
    attemptNumber: Number(pick(row, 'AttemptNumber', 'attemptNumber')),
    submittedAt: pick(row, 'SubmittedAt', 'submittedAt'),
    status: pick(row, 'SubmissionStatus', 'submissionStatus'),
    score: pick(row, 'Score', 'score'),
    fileName: pick(row, 'OriginalFileName', 'originalFileName'),
    fileUrl: pick(row, 'FileUrl', 'fileUrl') || '',
    submissionText: pick(row, 'SubmissionText', 'submissionText') || '',
    feedback: pick(row, 'Feedback', 'feedback') || '',
    isLate: Boolean(pick(row, 'IsLate', 'isLate'))
  }))
  const editable = submissions.value[0]
  if (canEditSubmission(editable) && !submissionText.value && !submissionFile.value) {
    submissionText.value = editable.submissionText
    submissionMode.value = editable.submissionText ? 'editor' : 'file'
  }
}
function canEditSubmission(item) {
  if (!item || !['DRAFT', 'SUBMITTED', 'RETURNED'].includes(item.status)) return false
  if (lesson.dueAt && Date.now() > new Date(lesson.dueAt).getTime()) return false
  return true
}
function editSubmission(item) {
  if (!canEditSubmission(item)) return
  submissionText.value = item.submissionText || ''
  submissionFile.value = null
  submissionMode.value = item.submissionText ? 'editor' : 'file'
  assignmentMessage.value = 'Bạn đang chỉnh sửa lần nộp hiện tại. Hãy cập nhật trước hạn nộp.'
  assignmentError.value = ''
  document.querySelector('.assignment-form')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}
function selectSubmissionFile(event) {
  submissionFile.value = event.target.files?.[0] || null
  if (submissionFile.value) submissionMode.value = 'file'
  assignmentMessage.value = ''
  assignmentError.value = ''
}
async function submitAssignment() {
  submitting.value = true
  assignmentError.value = ''
  assignmentMessage.value = ''
  try {
    const body = new FormData()
    if (submissionText.value) body.append('submissionText', submissionText.value)
    if (submissionFile.value) body.append('file', submissionFile.value)
    await axiosClient.post(`/lms/lessons/${lesson.id}/submissions`, body)
    submissionText.value = ''
    submissionFile.value = null
    submissionMode.value = 'editor'
    assignmentMessage.value = 'Bài làm đã được nộp thành công.'
    await loadSubmissions()
  } catch (e) {
    assignmentError.value = e.message
  } finally {
    submitting.value = false
  }
}
async function confirmSubmitAssignment() {
  showSubmitConfirm.value = false
  await submitAssignment()
}
async function saveAssignmentDraft() {
  await saveAssignment('/submission-draft', false)
  if (!assignmentError.value) assignmentMessage.value = 'Đã lưu nháp bài làm.'
}
async function saveAssignment(path, clearAfterSave) {
  submitting.value = true
  assignmentError.value = ''
  assignmentMessage.value = ''
  try {
    const body = new FormData()
    if (submissionText.value) body.append('submissionText', submissionText.value)
    if (submissionFile.value) body.append('file', submissionFile.value)
    await axiosClient.put(`/lms/lessons/${lesson.id}${path}`, body)
    if (clearAfterSave) {
      submissionText.value = ''
      submissionFile.value = null
    }
    await loadSubmissions()
  } catch (e) {
    assignmentError.value = e.message
  } finally {
    submitting.value = false
  }
}
async function markLessonComplete() {
  completing.value = true
  try {
    await stopStudySession(true)
    await loadPlayer()
  } finally {
    completing.value = false
  }
}
async function handleInteractiveCompleted() {
  await stopStudySession(true)
  if (course.id) {
    const detail = await axiosClient.get(`/lms/courses/${course.id}`, { params: { _fresh: Date.now() } })
    mapCourseContent(detail)
  }
}
function resetQuiz() {
  stopQuizCountdown()
  Object.assign(quiz, {
    id: 0,
    title: '',
    description: '',
    passingScore: 50,
    timeLimitMinutes: null,
    maxAttempts: 1,
    attemptCount: 0
  })
  quizQuestions.value = []
  quizAttempts.value = []
  quizAttemptId.value = 0
  quizAutoSubmitNotice.value = ''
  quizResult.value = null
  Object.keys(quizAnswers).forEach((key) => delete quizAnswers[key])
}
async function loadQuiz() {
  resetQuiz()
  const data = await axiosClient.get(`/lms/lessons/${lesson.id}/quiz`, { params: { _fresh: Date.now() } })
  const config = pick(data, 'Quiz', 'quiz') || {}
  Object.assign(quiz, {
    id: Number(pick(config, 'QuizID', 'quizID')),
    title: pick(config, 'Title', 'title') || lesson.title,
    description: pick(config, 'Description', 'description') || '',
    passingScore: Number(pick(config, 'PassingScore', 'passingScore') || 50),
    timeLimitMinutes: Number(pick(config, 'TimeLimitMinutes', 'timeLimitMinutes') || 0) || null,
    maxAttempts: Number(pick(config, 'MaxAttempts', 'maxAttempts') || 1),
    attemptCount: Number(pick(config, 'AttemptCount', 'attemptCount') || 0)
  })
  quizQuestions.value = (pick(data, 'Questions', 'questions') || []).map((row) => ({
    id: Number(pick(row, 'QuestionID', 'questionID')),
    type: pick(row, 'QuestionType', 'questionType'),
    text: pick(row, 'QuestionText', 'questionText'),
    score: Number(pick(row, 'Score', 'score') || 0),
    options: parseQuizOptions(pick(row, 'Options', 'options'))
  }))
  quizAttempts.value = (pick(data, 'Attempts', 'attempts') || []).map((row) => ({
    id: Number(pick(row, 'QuizAttemptID', 'quizAttemptID')),
    number: Number(pick(row, 'AttemptNumber', 'attemptNumber')),
    startedAt: pick(row, 'StartedAt', 'startedAt'),
    submittedAt: pick(row, 'SubmittedAt', 'submittedAt'),
    scorePercent: pick(row, 'ScorePercent', 'scorePercent'),
    passed: pick(row, 'Passed', 'passed'),
    status: pick(row, 'AttemptStatus', 'attemptStatus'),
    remainingSeconds: pick(row, 'RemainingSeconds', 'remainingSeconds')
  }))
  const active = quizAttempts.value.find((attempt) => attempt.status === 'IN_PROGRESS')
  quizAttemptId.value = active?.id || 0
  quizQuestions.value.forEach((question) => (quizAnswers[question.id] = question.type === 'MULTIPLE_CHOICE' ? [] : ''))
  if (active && quiz.timeLimitMinutes) startQuizCountdown(resolveQuizRemainingSeconds(active))
}
function parseQuizOptions(value) {
  const rows = typeof value === 'string' ? JSON.parse(value || '[]') : value || []
  return rows.map((row) => ({
    code: pick(row, 'OptionCode', 'optionCode'),
    text: pick(row, 'OptionText', 'optionText')
  }))
}
async function startQuiz() {
  quizBusy.value = true
  try {
    const result = await axiosClient.post(`/lms/lessons/${lesson.id}/quiz-attempts`)
    quizAttemptId.value = Number(pick(result, 'QuizAttemptID', 'quizAttemptID'))
    quizAutoSubmitNotice.value = ''
    if (quiz.timeLimitMinutes) {
      const serverRemaining = Number(pick(result, 'RemainingSeconds', 'remainingSeconds'))
      startQuizCountdown(Number.isFinite(serverRemaining) ? serverRemaining : quiz.timeLimitMinutes * 60)
    }
  } catch (e) {
    error.value = e.message
  } finally {
    quizBusy.value = false
  }
}
async function submitQuiz(mode = 'manual') {
  if (quizBusy.value || !quizAttemptId.value) return
  const automatic = mode === 'automatic'
  stopQuizCountdown(false)
  quizBusy.value = true
  try {
    const answers = quizQuestions.value.map((question) => ({
      questionId: question.id,
      answerText: Array.isArray(quizAnswers[question.id])
        ? [...quizAnswers[question.id]].sort().join('|')
        : quizAnswers[question.id] || ''
    }))
    const result = await axiosClient.post(`/lms/quiz-attempts/${quizAttemptId.value}/submit`, { answers })
    const completedResult = {
      score: Number(pick(result, 'Score', 'score') || 0),
      maxScore: Number(pick(result, 'MaxScore', 'maxScore') || 0),
      scorePercent: Number(pick(result, 'ScorePercent', 'scorePercent') || 0),
      passed: Boolean(pick(result, 'Passed', 'passed'))
    }
    quizAttemptId.value = 0
    await loadQuiz()
    quizResult.value = completedResult
    if (automatic) quizAutoSubmitNotice.value = 'Đã hết thời gian. Hệ thống đã tự động nộp và chấm bài.'
    await stopStudySession(true)
  } catch (e) {
    if (automatic) {
      try {
        await loadQuiz()
      } finally {
        quizAutoSubmitNotice.value = 'Đã hết thời gian. Lượt làm bài đã được hệ thống đóng.'
      }
    } else {
      error.value = e.message
      const remaining = Math.max(0, Math.ceil((quizCountdownDeadline - Date.now()) / 1000))
      if (quizAttemptId.value && quiz.timeLimitMinutes) startQuizCountdown(remaining)
    }
  } finally {
    quizBusy.value = false
  }
}
function resolveQuizRemainingSeconds(attempt) {
  const serverRemaining = Number(attempt?.remainingSeconds)
  if (Number.isFinite(serverRemaining)) return Math.max(0, serverRemaining)
  const rawStartedAt = String(attempt?.startedAt || '')
  if (!rawStartedAt) return Number(quiz.timeLimitMinutes || 0) * 60
  const normalizedStartedAt = /(?:Z|[+-]\d{2}:?\d{2})$/i.test(rawStartedAt) ? rawStartedAt : `${rawStartedAt}Z`
  const startedAt = Date.parse(normalizedStartedAt)
  if (!Number.isFinite(startedAt)) return Number(quiz.timeLimitMinutes || 0) * 60
  return Math.max(0, Math.ceil((startedAt + Number(quiz.timeLimitMinutes || 0) * 60000 - Date.now()) / 1000))
}
function startQuizCountdown(seconds) {
  stopQuizCountdown(false)
  quizCountdownDeadline = Date.now() + Math.max(0, Number(seconds) || 0) * 1000
  const updateCountdown = () => {
    quizSecondsRemaining.value = Math.max(0, Math.ceil((quizCountdownDeadline - Date.now()) / 1000))
    if (quizSecondsRemaining.value > 0) return
    stopQuizCountdown(false)
    if (quizAttemptId.value && !quizBusy.value) void submitQuiz('automatic')
  }
  updateCountdown()
  if (quizSecondsRemaining.value > 0) quizCountdownTimer = window.setInterval(updateCountdown, 1000)
}
function stopQuizCountdown(reset = true) {
  if (quizCountdownTimer) window.clearInterval(quizCountdownTimer)
  quizCountdownTimer = undefined
  if (reset) {
    quizSecondsRemaining.value = 0
    quizCountdownDeadline = 0
  }
}
function formatStudyTime(seconds) {
  const totalSeconds = Math.max(0, Math.floor(Number(seconds) || 0))
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const formatted = `${String(minutes).padStart(2, '0')}:${String(totalSeconds % 60).padStart(2, '0')}`
  return hours > 0 ? `${String(hours).padStart(2, '0')}:${formatted}` : formatted
}
function dateTimeText(value) {
  return value
    ? new Intl.DateTimeFormat('vi-VN', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
    : '—'
}
function submissionStatus(value) {
  return (
    {
      SUBMITTED: 'Đã nộp',
      GRADED: 'Đã chấm',
      RETURNED: 'Yêu cầu nộp lại',
      DRAFT: 'Bản nháp'
    }[value] || value
  )
}
function mapCourseContent(data) {
  const previouslyExpanded = new Set(expandedChapters.value)
  const chapterRows = pick(data, 'chapters', 'Chapters') || [],
    lessonRows = pick(data, 'lessons', 'Lessons') || []
  chapters.value = chapterRows
    .map((row) => {
      const id = Number(pick(row, 'Id', 'id'))
      return {
        id,
        title: pick(row, 'Title', 'title') || '',
        sortOrder: Number(pick(row, 'SortOrder', 'sortOrder') || 0),
        lessons: lessonRows
          .filter((x) => Number(pick(x, 'ChapterId', 'chapterId')) === id)
          .map((x) => ({
            id: Number(pick(x, 'Id', 'id')),
            title: pick(x, 'Title', 'title') || '',
            type: pick(x, 'LessonType', 'lessonType') || 'EDITOR',
            duration: Number(pick(x, 'DurationSeconds', 'durationSeconds') || 0),
            sortOrder: Number(pick(x, 'SortOrder', 'sortOrder') || 0),
            completed: Boolean(pick(x, 'Completed', 'completed'))
          }))
          .sort((first, second) => first.sortOrder - second.sortOrder || first.id - second.id)
      }
    })
    .sort((first, second) => first.sortOrder - second.sortOrder || first.id - second.id)

  const availableChapterIds = new Set(chapters.value.map((chapter) => chapter.id))
  const nextExpanded = new Set([...previouslyExpanded].filter((chapterId) => availableChapterIds.has(chapterId)))
  const activeChapter = chapters.value.find((chapter) => chapter.lessons.some((item) => item.id === lesson.id))
  if (activeChapter) nextExpanded.add(activeChapter.id)
  expandedChapters.value = nextExpanded
}
function toggleChapter(chapterId) {
  const next = new Set(expandedChapters.value)
  if (next.has(chapterId)) next.delete(chapterId)
  else next.add(chapterId)
  expandedChapters.value = next
}
function lessonUrl(item) {
  return `/lms/courses/${course.id}/lessons/${item.id}`
}
function handleProgress(value) {
  Object.assign(progress, value)
  if (progress.currentTime - lastSavedAt.value >= 10) void saveProgress()
}
async function saveProgress() {
  if (!video.id || savingProgress.value) return
  savingProgress.value = true
  try {
    await axiosClient.post('/lms/progress/video', {
      lessonId: lesson.id,
      videoId: video.id,
      currentTime: progress.currentTime,
      maxWatchedTime: progress.maxWatchedTime,
      watchPercent: progress.watchPercent
    })
    lastSavedAt.value = progress.currentTime
  } catch (e) {
    error.value = e.message
  } finally {
    savingProgress.value = false
  }
}
async function submitInteractionAnswer(item, answers) {
  return axiosClient.post('/lms/answers', {
    lessonId: lesson.id,
    videoId: video.id,
    interactionId: item.id,
    questionId: item.questionId,
    answers,
    timeInVideo: item.timeSeconds,
    timeSpent: 0
  })
}
function handleAnswered({ interaction, result }) {
  interaction.answered = true
  interaction.attempts = Number(pick(result, 'attemptNumber', 'AttemptNumber') || 1)
  currentScore.value = Number(
    pick(result, 'currentLessonScore', 'CurrentLessonScore') ||
      currentScore.value + Number(pick(result, 'scoreAwarded', 'ScoreAwarded') || 0)
  )
  void saveProgress()
}
</script>

<style scoped src="../../assets/css/pages/lms/lesson-player.css"></style>
