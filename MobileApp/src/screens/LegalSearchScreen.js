import React, { useState } from 'react';
import { StyleSheet, View, Text, TextInput, TouchableOpacity, ScrollView, SafeAreaView, ActivityIndicator, LayoutAnimation } from 'react-native';
import { Colors } from '../theme/colors';
import { Search, Sparkles, FileText, ChevronRight, BookOpen, ExternalLink } from 'lucide-react-native';
import api from '../api/network';
import { Asset } from 'expo-asset';
import * as Sharing from 'expo-sharing';
import { LEGAL_ASSETS } from '../constants/legalAssets';
import { Alert, ActionSheetIOS, Platform } from 'react-native';
import { AIService } from '../services/aiService';

export default function LegalSearchScreen() {
    const [query, setQuery] = useState('');
    const [loading, setLoading] = useState(false);
    const [answer, setAnswer] = useState('');
    const [citations, setCitations] = useState([]);
    const [selectedModel, setSelectedModel] = useState('kimi-k2.5-free');
    const [isPreparingDoc, setIsPreparingDoc] = useState(false);

    const openOriginalDoc = async (docId) => {
        try {
            const assetModule = LEGAL_ASSETS[docId];
            if (!assetModule) {
                Alert.alert('Lỗi', 'Không tìm thấy file nguồn cho tài liệu này.');
                return;
            }

            setIsPreparingDoc(true);
            const asset = Asset.fromModule(assetModule);
            await asset.downloadAsync();

            if (await Sharing.isAvailableAsync()) {
                await Sharing.shareAsync(asset.localUri, {
                    mimeType: docId.includes('luat') ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' : 'application/pdf',
                    dialogTitle: 'Mở tài liệu'
                });
            } else {
                Alert.alert('Lỗi', 'Thiết bị của bạn không hỗ trợ chia sẻ/xem tài liệu này.');
            }
        } catch (error) {
            console.error(error);
            Alert.alert('Lỗi', 'Không thể mở tài liệu. Vui lòng thử lại sau.');
        } finally {
            setIsPreparingDoc(false);
        }
    };

    const handleSearch = async () => {
        if (!query.trim()) return;
        setLoading(true);
        setAnswer('');
        setCitations([]);

        try {
            const result = await AIService.searchLegal(query, selectedModel);

            LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
            setAnswer(result);

            // Heuristic to show citations based on keywords in answer
            const docMap = [
                { id: 'luatDienLuc2024', name: 'Luật Điện lực 2024', keywords: ['2024', '61/2024'] },
                { id: 'thongTu60_2025', name: 'Thông tư 60/2025/TT-BCT', keywords: ['60/2025', 'TT-BCT'] },
                { id: 'quyDinhGiaBanDien2025', name: 'QĐ 1279/QĐ-BCT', keywords: ['1279', 'biểu giá'] },
                { id: 'quyDinhKiemTraDienLuc2022', name: 'TT 42/2022/TT-BCT', keywords: ['42/2022', 'kiểm tra'] },
                { id: 'nghiDinh17_2022', name: 'Nghị định 17/2022/NĐ-CP', keywords: ['17/2022', 'xử phạt'] }
            ];

            const detectedCitations = docMap
                .filter(doc => doc.keywords.some(k => result.includes(k)))
                .map((doc, idx) => ({
                    id: String(idx + 1),
                    docId: doc.id,
                    docName: doc.name,
                    page: '?',
                    excerpt: 'Nhấn để xem văn bản gốc liên quan đến nội dung trả lời.'
                }));

            setCitations(detectedCitations);
        } catch (error) {
            console.error('Search failed', error);
            Alert.alert('Lỗi AI', 'Không thể kết nối tới dịch vụ AI. Vui lòng thử lại sau.');
        } finally {
            setLoading(false);
        }
    };

    const showModelSelector = () => {
        const models = [
            { id: 'kimi-k2.5-free', label: 'Kimi K2.5 (Free)' },
            { id: 'minimax-m2.5-free', label: 'Minimax M2.5 (Free)' },
            { id: 'trinity-large-preview-free', label: 'Trinity Large (Free)' },
            { id: 'glm-4.7-free', label: 'GLM-4.7 (Free)' }
        ];

        if (Platform.OS === 'ios') {
            ActionSheetIOS.showActionSheetWithOptions(
                {
                    options: ['Hủy', ...models.map(m => m.label)],
                    cancelButtonIndex: 0,
                    title: 'Chọn mô hình AI'
                },
                (buttonIndex) => {
                    if (buttonIndex > 0) {
                        setSelectedModel(models[buttonIndex - 1].id);
                    }
                }
            );
        } else {
            // Basic fallback for Android if needed, though usually we'd use a Modal or Picker
            Alert.alert(
                'Chọn mô hình',
                '',
                models.map(m => ({
                    text: m.label,
                    onPress: () => setSelectedModel(m.id)
                })).concat([{ text: 'Hủy', style: 'cancel' }])
            );
        }
    };

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <Text style={styles.headerTitle}>Tra cứu pháp lý</Text>
            </View>

            <ScrollView contentContainerStyle={styles.scroll}>
                <View style={styles.card}>
                    <Text style={styles.sectionTitle}>Câu hỏi</Text>
                    <TextInput
                        style={styles.textArea}
                        placeholder="Nhập câu hỏi hoặc nội dung cần tra cứu..."
                        multiline
                        numberOfLines={4}
                        value={query}
                        onChangeText={setQuery}
                        textAlignVertical="top"
                    />

                    <View style={styles.modelRow}>
                        <Text style={styles.label}>Mô hình AI:</Text>
                        <TouchableOpacity style={styles.modelSelector} onPress={showModelSelector}>
                            <Text style={styles.modelText}>
                                {selectedModel === 'kimi-k2.5-free' ? 'Kimi K2.5' :
                                    selectedModel === 'minimax-m2.5-free' ? 'Minimax M2.5' :
                                        selectedModel === 'trinity-large-preview-free' ? 'Trinity Large' : 'GLM-4.7'}
                            </Text>
                        </TouchableOpacity>
                    </View>

                    <TouchableOpacity
                        style={[styles.searchBtn, (!query.trim() || loading) && styles.btnDisabled]}
                        onPress={handleSearch}
                        disabled={!query.trim() || loading}
                    >
                        {loading ? (
                            <ActivityIndicator color="#fff" size="small" />
                        ) : (
                            <>
                                <Sparkles size={18} color="#fff" style={{ marginRight: 8 }} />
                                <Text style={styles.searchBtnText}>Tra cứu với AI</Text>
                            </>
                        )}
                    </TouchableOpacity>
                </View>

                {answer !== '' && (
                    <View style={styles.resultCard}>
                        <Text style={styles.resultTitle}>Kết quả</Text>
                        <Text style={styles.answerText}>{answer}</Text>
                    </View>
                )}

                {citations.length > 0 && (
                    <View style={styles.citationSection}>
                        <Text style={styles.citationTitle}>Nguồn tham khảo</Text>
                        {citations.map(c => (
                            <TouchableOpacity
                                key={c.id}
                                style={styles.citationCard}
                                onPress={() => openOriginalDoc(c.docId)}
                            >
                                <View style={[styles.iconBox, { backgroundColor: 'rgba(0,122,255,0.1)' }]}>
                                    <FileText size={20} color={Colors.primary} />
                                </View>
                                <View style={styles.citationInfo}>
                                    <View style={styles.citedHeader}>
                                        <Text style={styles.docName}>{c.docName}</Text>
                                        <ExternalLink size={14} color={Colors.primary} />
                                    </View>
                                    <View style={styles.pageBadge}>
                                        <Text style={styles.pageText}>Trang {c.page}</Text>
                                    </View>
                                    <Text style={styles.excerpt} numberOfLines={3}>{c.excerpt}</Text>
                                </View>
                                <ChevronRight size={16} color={Colors.border} />
                            </TouchableOpacity>
                        ))}
                    </View>
                )}

                <View style={styles.sectionHeader}>
                    <BookOpen size={18} color={Colors.primary} style={{ marginRight: 8 }} />
                    <Text style={styles.sectionTitle}>Danh mục văn bản hỗ trợ</Text>
                </View>
                <View style={styles.docList}>
                    {[
                        { id: 'luatDienLuc2024', title: 'Luật Điện lực 2024 (61/2024/QH15)' },
                        { id: 'thongTu60_2025', title: 'Thông tư 60/2025/TT-BCT' },
                        { id: 'quyDinhGiaBanDien2025', title: 'Quyết định 1279/QĐ-BCT (2025)' },
                        { id: 'quyDinhKiemTraDienLuc2022', title: 'Thông tư 42/2022/TT-BCT' },
                        { id: 'nghiDinh17_2022', title: 'Nghị định 17/2022/NĐ-CP' }
                    ].map((doc, index) => (
                        <TouchableOpacity
                            key={index}
                            style={styles.docItem}
                            onPress={() => openOriginalDoc(doc.id)}
                        >
                            <View style={styles.dot} />
                            <Text style={styles.docItemText}>{doc.title}</Text>
                            <Spacer />
                            <ExternalLink size={14} color={Colors.border} />
                        </TouchableOpacity>
                    ))}
                </View>
            </ScrollView>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: Colors.background },
    header: {
        height: 56,
        backgroundColor: Colors.white,
        justifyContent: 'center',
        paddingHorizontal: 16,
        borderBottomWidth: 1,
        borderBottomColor: '#eee'
    },
    headerTitle: { fontSize: 20, fontWeight: 'bold' },
    scroll: { padding: 16 },
    card: { backgroundColor: Colors.white, borderRadius: 16, padding: 16, marginBottom: 16, shadowColor: '#000', shadowOpacity: 0.05, elevation: 1 },
    sectionTitle: { fontSize: 16, fontWeight: 'bold', marginBottom: 12 },
    textArea: {
        backgroundColor: '#F5F5F7',
        borderRadius: 12,
        padding: 12,
        fontSize: 15,
        minHeight: 120,
        borderWidth: 1,
        borderColor: '#eee',
        color: Colors.text
    },
    modelRow: { flexDirection: 'row', alignItems: 'center', marginTop: 12, marginBottom: 16 },
    label: { fontSize: 14, color: Colors.textSecondary, marginRight: 8 },
    modelSelector: { paddingHorizontal: 12, paddingVertical: 4, borderRadius: 6, backgroundColor: 'rgba(0,122,255,0.05)' },
    modelText: { fontSize: 13, color: Colors.primary, fontWeight: '600' },
    searchBtn: {
        backgroundColor: Colors.primary,
        height: 48,
        borderRadius: 12,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: Colors.primary,
        shadowOpacity: 0.3,
        shadowRadius: 5,
        elevation: 3
    },
    searchBtnText: { color: '#fff', fontSize: 16, fontWeight: 'bold' },
    btnDisabled: { opacity: 0.5 },
    resultCard: { backgroundColor: '#F0F7FF', borderRadius: 16, padding: 16, marginBottom: 16, borderWidth: 1, borderColor: 'rgba(0,122,255,0.1)' },
    resultTitle: { fontSize: 16, fontWeight: 'bold', marginBottom: 10, color: Colors.primary },
    answerText: { fontSize: 15, lineHeight: 22, color: Colors.text },
    citationSection: { marginTop: 8 },
    citationTitle: { fontSize: 16, fontWeight: 'bold', marginBottom: 12, color: Colors.primary },
    citationCard: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.white,
        borderRadius: 12,
        padding: 16,
        marginBottom: 12,
        shadowColor: '#000',
        shadowOpacity: 0.05,
        elevation: 2
    },
    iconBox: { width: 40, height: 40, borderRadius: 10, justifyContent: 'center', alignItems: 'center' },
    citationInfo: { flex: 1, marginLeft: 12, marginRight: 8 },
    docName: { fontSize: 14, fontWeight: 'bold', color: Colors.text },
    pageBadge: { alignSelf: 'flex-start', backgroundColor: 'rgba(0,122,255,0.1)', paddingHorizontal: 6, paddingVertical: 2, borderRadius: 4, marginVertical: 4 },
    pageText: { fontSize: 10, color: Colors.primary, fontWeight: 'bold' },
    excerpt: { fontSize: 12, color: Colors.textSecondary, lineHeight: 18 },
    sectionHeader: { flexDirection: 'row', alignItems: 'center', marginTop: 8, marginBottom: 12 },
    docList: { backgroundColor: Colors.white, borderRadius: 12, padding: 12, marginBottom: 20 },
    docItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: '#f5f5f5' },
    dot: { width: 6, height: 6, borderRadius: 3, backgroundColor: Colors.primary, marginRight: 10 },
    docItemText: { fontSize: 13, color: Colors.textSecondary, flex: 1 },
    citedHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }
});

const Spacer = () => <View style={{ flex: 1 }} />;
