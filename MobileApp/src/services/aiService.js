import api from '../api/network';

export const AIService = {
    async searchLegal(query, model = "glm-5-free") {
        const candidates = [model, 'glm-5-free', 'kimi-k2.5-free', 'glm-4.7-free'];
        let lastError = null;

        for (const candidate of candidates) {
            try {
                const response = await api.post('/ai/search', { query, model: candidate });
                if (response?.data?.content) {
                    return response.data.content;
                }
            } catch (error) {
                lastError = error;
            }
        }

        if (lastError) {
            console.error('AI Service Error:', lastError.response?.data || lastError.message);
            throw lastError;
        }

        return 'Hiện chưa có phản hồi từ hệ thống AI. Vui lòng thử lại sau.';
    }
};
