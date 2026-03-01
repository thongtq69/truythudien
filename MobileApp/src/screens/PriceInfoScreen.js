import React, { useState, useEffect } from 'react';
import { StyleSheet, View, Text, ScrollView, TouchableOpacity, SafeAreaView, TextInput, Alert, KeyboardAvoidingView, Platform } from 'react-native';
import { Colors } from '../theme/colors';
import { X, FileText, Edit3, Check, RotateCcw, Clock, ChevronRight, BookOpen, ExternalLink } from 'lucide-react-native';
import { useSettings, PRICE_PERIODS, DEFAULT_PRICE_TABLES } from '../context/SettingsContext';
import { LEGAL_METADATA } from '../constants/legalMetadata';
import { LEGAL_ASSETS } from '../constants/legalAssets';
import { Asset } from 'expo-asset';
import * as Sharing from 'expo-sharing';
import { useAuth } from '../context/AuthContext';

export default function PriceInfoScreen({ onClose }) {
    const { priceTables, selectedPeriod, selectPeriod, updatePriceForPeriod, resetToDefaults, PRICE_PERIODS } = useSettings();
    const { user } = useAuth();
    const canEditPrices = user?.role === 'admin';
    const [isEditing, setIsEditing] = useState(false);
    const [viewingPeriod, setViewingPeriod] = useState(selectedPeriod);
    const [editedPrices, setEditedPrices] = useState(priceTables[viewingPeriod]);
    const [selectedDoc, setSelectedDoc] = useState(null);
    const [isPreparingDoc, setIsPreparingDoc] = useState(false);

    useEffect(() => {
        setEditedPrices(priceTables[viewingPeriod]);
    }, [viewingPeriod, priceTables]);

    const currentPrices = priceTables[viewingPeriod] || DEFAULT_PRICE_TABLES[viewingPeriod];

    const handleSave = () => {
        if (!canEditPrices) {
            Alert.alert('Không có quyền', 'Chỉ admin mới được chỉnh sửa bảng giá điện.');
            return;
        }
        updatePriceForPeriod(viewingPeriod, editedPrices);
        setIsEditing(false);
        Alert.alert('Thành công', `Đã lưu bảng giá ${PRICE_PERIODS[viewingPeriod]?.name || viewingPeriod}`);
    };

    const handleReset = () => {
        if (!canEditPrices) {
            Alert.alert('Không có quyền', 'Chỉ admin mới được chỉnh sửa bảng giá điện.');
            return;
        }
        Alert.alert(
            'Xác nhận',
            `Khôi phục bảng giá mặc định cho "${PRICE_PERIODS[viewingPeriod]?.name}"?`,
            [
                { text: 'Hủy', style: 'cancel' },
                {
                    text: 'Khôi phục',
                    style: 'destructive',
                    onPress: () => {
                        resetToDefaults(viewingPeriod);
                        setEditedPrices(DEFAULT_PRICE_TABLES[viewingPeriod]);
                        setIsEditing(false);
                    }
                }
            ]
        );
    };

    const updateTierPrice = (tier, value) => {
        const numValue = parseInt(value) || 0;
        setEditedPrices({ ...editedPrices, [tier]: numValue });
    };

    const updateVAT = (value) => {
        const numValue = parseFloat(value) || 0;
        setEditedPrices({ ...editedPrices, vat: numValue / 100 });
    };

    const formatPrice = (price) => {
        return (price || 0).toLocaleString('vi-VN');
    };

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

    const tierItems = [
        { key: 'tier1', label: 'Bậc 1 (0-50 kWh)' },
        { key: 'tier2', label: 'Bậc 2 (51-100 kWh)' },
        { key: 'tier3', label: 'Bậc 3 (101-200 kWh)' },
        { key: 'tier4', label: 'Bậc 4 (201-300 kWh)' },
        { key: 'tier5', label: 'Bậc 5 (301-400 kWh)' },
        { key: 'tier6', label: 'Bậc 6 (401+ kWh)' },
    ];

    const otherItems = [
        { key: 'production', label: 'Sản xuất (SXBT)' },
        { key: 'business', label: 'Kinh doanh (KDDV)' },
        { key: 'hcsn_hospital', label: 'HCSN - Bệnh viện, trường học' },
        { key: 'hcsn_lighting', label: 'HCSN - Chiếu sáng công cộng' },
    ];

    const docs = [
        { id: 'luatDienLuc2024', title: 'Luật Điện lực 2024 (61/2024/QH15)', subtitle: 'Luật Điện lực (có hiệu lực từ 01/02/2025)' },
        { id: 'thongTu60_2025', title: 'Thông tư 60/2025/TT-BCT', subtitle: 'Quy định về giá bán điện' },
        { id: 'quyDinhGiaBanDien2025', title: 'Quyết định 1279/QĐ-BCT', subtitle: 'Biểu giá bán lẻ điện 2025' },
        { id: 'quyDinhKiemTraDienLuc2022', title: 'Thông tư 42/2022/TT-BCT', subtitle: 'Kiểm tra hoạt động điện lực' },
        { id: 'nghiDinh17_2022', title: 'Nghị định 17/2022/NĐ-CP', subtitle: 'Sửa đổi, bổ sung xử phạt VPHC' }
    ];

    return (
        <SafeAreaView style={styles.container}>
            <KeyboardAvoidingView
                behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
                style={{ flex: 1 }}
            >
                    <View style={styles.header}>
                    {canEditPrices ? (
                        <TouchableOpacity onPress={handleReset} style={styles.headerBtn}>
                            <RotateCcw size={18} color={Colors.textSecondary} />
                        </TouchableOpacity>
                    ) : null}
                    <Text style={styles.headerTitle}>Bảng giá điện</Text>
                    <TouchableOpacity onPress={onClose} style={styles.closeBtn}>
                        <Text style={styles.closeText}>Đóng</Text>
                    </TouchableOpacity>
                </View>

                <ScrollView contentContainerStyle={styles.scroll}>
                    {/* Period Tab Selector */}
                    <View style={styles.periodTabContainer}>
                        <View style={styles.periodHeader}>
                            <Clock size={16} color={Colors.primary} />
                            <Text style={styles.periodHeaderText}>Chọn thời kỳ giá:</Text>
                        </View>
                        <View style={styles.periodTabs}>
                            {Object.values(PRICE_PERIODS).map((period) => (
                                <TouchableOpacity
                                    key={period.id}
                                    style={[
                                        styles.periodTab,
                                        viewingPeriod === period.id && styles.periodTabActive
                                    ]}
                                    onPress={() => {
                                        setViewingPeriod(period.id);
                                        setIsEditing(false);
                                    }}
                                >
                                    <Text style={[
                                        styles.periodTabText,
                                        viewingPeriod === period.id && styles.periodTabTextActive
                                    ]}>
                                        {period.shortName}
                                    </Text>
                                    {selectedPeriod === period.id && (
                                        <View style={styles.activeIndicator}>
                                            <Text style={styles.activeIndicatorText}>Đang dùng</Text>
                                        </View>
                                    )}
                                </TouchableOpacity>
                            ))}
                        </View>
                    </View>

                    {/* Apply Button */}
                    {viewingPeriod !== selectedPeriod && (
                        <TouchableOpacity
                            style={styles.applyPeriodBtn}
                            onPress={() => {
                                selectPeriod(viewingPeriod);
                                Alert.alert('Thành công', `Đã chuyển sang áp dụng bảng giá "${PRICE_PERIODS[viewingPeriod]?.name}"`);
                            }}
                        >
                            <Text style={styles.applyPeriodBtnText}>
                                Áp dụng bảng giá này
                            </Text>
                        </TouchableOpacity>
                    )}

                    {/* Giá sinh hoạt bậc thang */}
                    <View style={styles.section}>
                        <View style={styles.sectionHeaderRow}>
                            <Text style={styles.sectionTitle}>GIÁ SINH HOẠT BẬC THANG</Text>
                            <TouchableOpacity disabled={!canEditPrices} onPress={() => setIsEditing(!isEditing)} style={!canEditPrices ? { opacity: 0.35 } : null}>
                                {isEditing ? (
                                    <Check size={18} color={Colors.success} />
                                ) : (
                                    <Edit3 size={16} color={Colors.primary} />
                                )}
                            </TouchableOpacity>
                        </View>
                        {!canEditPrices && (
                            <Text style={styles.permissionText}>Chỉ tài khoản admin mới có quyền chỉnh sửa bảng giá điện.</Text>
                        )}
                        <View style={styles.card}>
                            {tierItems.map((item, idx) => (
                                <View key={item.key} style={[styles.item, idx === tierItems.length - 1 && styles.noBorder]}>
                                    <Text style={styles.itemLabel}>{item.label}</Text>
                                    {isEditing ? (
                                        <View style={styles.inputRow}>
                                            <TextInput
                                                style={styles.priceInput}
                                                keyboardType="numeric"
                                                value={String(editedPrices[item.key] || 0)}
                                                onChangeText={(val) => updateTierPrice(item.key, val)}
                                            />
                                            <Text style={styles.unit}>đ/kWh</Text>
                                        </View>
                                    ) : (
                                        <Text style={styles.itemValue}>{formatPrice(currentPrices[item.key])} đ/kWh</Text>
                                    )}
                                </View>
                            ))}
                        </View>
                    </View>

                    {/* Giá ngoài mục đích sinh hoạt */}
                    <View style={styles.section}>
                        <Text style={styles.sectionTitle}>GIÁ NGOÀI MỤC ĐÍCH SINH HOẠT</Text>
                        <View style={styles.card}>
                            {otherItems.map((item, idx) => (
                                <View key={item.key} style={[styles.item, idx === otherItems.length - 1 && styles.noBorder]}>
                                    <Text style={[styles.itemLabel, { flex: 1 }]}>{item.label}</Text>
                                    {isEditing ? (
                                        <View style={styles.inputRow}>
                                            <TextInput
                                                style={styles.priceInput}
                                                keyboardType="numeric"
                                                value={String(editedPrices[item.key] || 0)}
                                                onChangeText={(val) => updateTierPrice(item.key, val)}
                                            />
                                            <Text style={styles.unit}>đ/kWh</Text>
                                        </View>
                                    ) : (
                                        <Text style={styles.itemValue}>{formatPrice(currentPrices[item.key])} đ/kWh</Text>
                                    )}
                                </View>
                            ))}
                        </View>
                    </View>

                    {/* Thuế VAT */}
                    <View style={styles.section}>
                        <Text style={styles.sectionTitle}>THUẾ VAT</Text>
                        <View style={styles.card}>
                            <View style={[styles.item, styles.noBorder]}>
                                <Text style={styles.itemLabel}>Thuế suất</Text>
                                {isEditing ? (
                                    <View style={styles.inputRow}>
                                        <TextInput
                                            style={styles.priceInput}
                                            keyboardType="numeric"
                                            value={String(Math.round((editedPrices.vat || 0.08) * 100))}
                                            onChangeText={updateVAT}
                                        />
                                        <Text style={styles.unit}>%</Text>
                                    </View>
                                ) : (
                                    <Text style={styles.itemValue}>{Math.round((currentPrices.vat || 0.08) * 100)}%</Text>
                                )}
                            </View>
                        </View>
                    </View>

                    {isEditing && canEditPrices && (
                        <TouchableOpacity style={styles.saveBtn} onPress={handleSave}>
                            <Text style={styles.saveBtnText}>Lưu thay đổi</Text>
                        </TouchableOpacity>
                    )}

                    {/* Thông tin pháp lý */}
                    <View style={styles.section}>
                        <Text style={styles.sectionTitle}>THÔNG TIN PHÁP LÝ</Text>
                        {docs.map((doc, dIdx) => (
                            <TouchableOpacity
                                key={dIdx}
                                style={styles.docCard}
                                onPress={() => setSelectedDoc({ ...LEGAL_METADATA[doc.id], id: doc.id })}
                            >
                                <View style={styles.docIcon}>
                                    <FileText size={20} color={Colors.primary} />
                                </View>
                                <View style={styles.docInfo}>
                                    <Text style={styles.docTitle}>{doc.title}</Text>
                                    <Text style={styles.docSubtitle}>{doc.subtitle}</Text>
                                </View>
                                <ChevronRight size={18} color={Colors.border} />
                            </TouchableOpacity>
                        ))}
                    </View>
                </ScrollView>
            </KeyboardAvoidingView>

            {/* Document Detail Modal */}
            {selectedDoc && (
                <View style={styles.detailOverlay}>
                    <SafeAreaView style={styles.detailContainer}>
                        <View style={styles.detailHeader}>
                            <Text style={styles.detailTitle} numberOfLines={1}>{selectedDoc.title}</Text>
                            <TouchableOpacity onPress={() => setSelectedDoc(null)} style={styles.detailClose}>
                                <X size={24} color={Colors.text} />
                            </TouchableOpacity>
                        </View>
                        <ScrollView style={styles.detailScroll} contentContainerStyle={styles.detailContent}>
                            <View style={styles.summaryCard}>
                                <BookOpen size={24} color={Colors.primary} />
                                <Text style={styles.summaryText}>{selectedDoc.description}</Text>
                            </View>

                            <TouchableOpacity
                                style={[styles.openDocBtn, isPreparingDoc && styles.openDocBtnDisabled]}
                                onPress={() => openOriginalDoc(selectedDoc.id)}
                                disabled={isPreparingDoc}
                            >
                                <ExternalLink size={20} color="#fff" style={{ marginRight: 8 }} />
                                <Text style={styles.openDocBtnText}>
                                    {isPreparingDoc ? 'Đang tải file...' : 'Xem văn bản gốc (PDF/DOCX)'}
                                </Text>
                            </TouchableOpacity>

                            <Text style={styles.detailSectionTitle}>NỘI DUNG CHÍNH</Text>
                            {selectedDoc.sections.map((section, sIdx) => (
                                <View key={sIdx} style={styles.sectionItem}>
                                    <Text style={styles.sectionItemTitle}>{section.title}</Text>
                                    <Text style={styles.sectionItemContent}>{section.content}</Text>
                                </View>
                            ))}
                        </ScrollView>
                    </SafeAreaView>
                </View>
            )}
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: Colors.background },
    header: {
        height: 56,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        borderBottomWidth: 1,
        borderBottomColor: '#eee',
        backgroundColor: Colors.white
    },
    headerTitle: { fontSize: 17, fontWeight: 'bold' },
    headerBtn: { position: 'absolute', left: 16, padding: 8 },
    closeBtn: { position: 'absolute', right: 16, padding: 8, backgroundColor: '#f0f0f5', borderRadius: 20 },
    closeText: { fontSize: 14, fontWeight: '600', color: Colors.text },
    scroll: { padding: 16, paddingBottom: 40 },

    // Period Tab Styles
    periodTabContainer: { marginBottom: 20 },
    periodHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
    periodHeaderText: { fontSize: 14, fontWeight: '600', marginLeft: 6 },
    periodTabs: { flexDirection: 'row', gap: 10 },
    periodTab: {
        flex: 1,
        paddingVertical: 12,
        backgroundColor: Colors.white,
        borderRadius: 12,
        alignItems: 'center',
        borderWidth: 2,
        borderColor: 'transparent'
    },
    periodTabActive: {
        borderColor: Colors.primary,
        backgroundColor: 'rgba(0,122,255,0.05)'
    },
    periodTabText: { fontSize: 14, fontWeight: '600', color: Colors.textSecondary },
    periodTabTextActive: { color: Colors.primary },
    activeIndicator: {
        marginTop: 4,
        backgroundColor: Colors.success,
        paddingHorizontal: 8,
        paddingVertical: 2,
        borderRadius: 10
    },
    activeIndicatorText: { fontSize: 10, color: '#fff', fontWeight: 'bold' },

    applyPeriodBtn: {
        backgroundColor: Colors.warning,
        paddingVertical: 12,
        borderRadius: 10,
        alignItems: 'center',
        marginBottom: 20
    },
    applyPeriodBtnText: { color: '#fff', fontSize: 14, fontWeight: 'bold' },

    section: { marginBottom: 24 },
    sectionHeaderRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8, marginHorizontal: 8 },
    sectionTitle: { fontSize: 13, color: Colors.textSecondary, textTransform: 'uppercase', marginBottom: 8, marginLeft: 8 },
    permissionText: { fontSize: 12, color: Colors.warning, marginHorizontal: 8, marginBottom: 8, fontWeight: '600' },
    card: { backgroundColor: Colors.white, borderRadius: 12, overflow: 'hidden' },
    item: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: 16,
        borderBottomWidth: StyleSheet.hairlineWidth,
        borderBottomColor: '#eee'
    },
    noBorder: { borderBottomWidth: 0 },
    itemLabel: { fontSize: 15, color: Colors.text },
    itemValue: { fontSize: 15, fontWeight: '500', color: Colors.text },
    inputRow: { flexDirection: 'row', alignItems: 'center' },
    priceInput: {
        backgroundColor: '#f5f5f7',
        borderRadius: 8,
        paddingHorizontal: 12,
        paddingVertical: 6,
        fontSize: 15,
        textAlign: 'right',
        minWidth: 80,
        borderWidth: 1,
        borderColor: Colors.primary
    },
    unit: { fontSize: 13, color: Colors.textSecondary, marginLeft: 4 },
    saveBtn: {
        backgroundColor: Colors.primary,
        height: 48,
        borderRadius: 12,
        justifyContent: 'center',
        alignItems: 'center',
        marginBottom: 24
    },
    saveBtnText: { color: '#fff', fontSize: 16, fontWeight: 'bold' },
    docCard: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.white,
        borderRadius: 12,
        padding: 16,
        marginBottom: 12
    },
    docIcon: { width: 40, height: 40, borderRadius: 8, backgroundColor: 'rgba(0,122,255,0.05)', justifyContent: 'center', alignItems: 'center', marginRight: 12 },
    docInfo: { flex: 1 },
    docTitle: { fontSize: 15, fontWeight: 'bold', color: Colors.text },
    docSubtitle: { fontSize: 12, color: Colors.textSecondary, marginTop: 2 },

    // Detail Modal Styles
    detailOverlay: {
        position: 'absolute',
        top: 0, left: 0, right: 0, bottom: 0,
        backgroundColor: 'rgba(0,0,0,0.5)',
        zIndex: 1000
    },
    detailContainer: {
        flex: 1,
        backgroundColor: Colors.background,
        marginTop: 50,
        borderTopLeftRadius: 24,
        borderTopRightRadius: 24,
        overflow: 'hidden'
    },
    detailHeader: {
        height: 60,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 20,
        backgroundColor: Colors.white,
        borderBottomWidth: 1,
        borderBottomColor: '#eee'
    },
    detailTitle: { fontSize: 16, fontWeight: 'bold', color: Colors.text, flex: 1, marginRight: 10 },
    detailClose: { padding: 4 },
    detailScroll: { flex: 1 },
    detailContent: { padding: 20 },
    summaryCard: {
        backgroundColor: Colors.white,
        borderRadius: 16,
        padding: 20,
        flexDirection: 'row',
        alignItems: 'flex-start',
        marginBottom: 24,
        shadowColor: '#000',
        shadowOpacity: 0.05,
        shadowRadius: 10,
        elevation: 2
    },
    summaryText: {
        flex: 1,
        marginLeft: 15,
        fontSize: 15,
        lineHeight: 22,
        color: Colors.text
    },
    detailSectionTitle: {
        fontSize: 13,
        fontWeight: 'bold',
        color: Colors.textSecondary,
        marginBottom: 15,
        letterSpacing: 1
    },
    sectionItem: {
        backgroundColor: Colors.white,
        borderRadius: 12,
        padding: 16,
        marginBottom: 15
    },
    sectionItemTitle: {
        fontSize: 15,
        fontWeight: 'bold',
        color: Colors.primary,
        marginBottom: 8
    },
    sectionItemContent: {
        fontSize: 14,
        lineHeight: 20,
        color: Colors.textSecondary
    },
    openDocBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: Colors.primary,
        paddingVertical: 14,
        borderRadius: 12,
        marginBottom: 24,
        shadowColor: Colors.primary,
        shadowOpacity: 0.2,
        shadowRadius: 5,
        elevation: 3
    },
    openDocBtnDisabled: {
        backgroundColor: Colors.border,
        shadowOpacity: 0
    },
    openDocBtnText: {
        color: '#fff',
        fontSize: 16,
        fontWeight: 'bold'
    }
});
