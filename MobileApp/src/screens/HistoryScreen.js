import React, { useState, useEffect, useCallback } from 'react';
import { StyleSheet, View, Text, FlatList, TouchableOpacity, RefreshControl, ActivityIndicator, SafeAreaView, LayoutAnimation, Modal, ScrollView } from 'react-native';
import { Colors } from '../theme/colors';
import api from '../api/network';
import { Clock, User, ChevronRight, Calculator, Calendar, X, FileText, CheckCircle2 } from 'lucide-react-native';

export default function HistoryScreen() {
    const [history, setHistory] = useState([]);
    const [loading, setLoading] = useState(true);
    const [refreshing, setRefreshing] = useState(false);
    const [selectedItem, setSelectedItem] = useState(null);
    const [detailVisible, setDetailVisible] = useState(false);

    const fetchHistory = async () => {
        try {
            const response = await api.get('/calculations');
            LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
            setHistory(response.data);
        } catch (error) {
            console.error('Fetch history failed', error);
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    };

    useEffect(() => {
        fetchHistory();
    }, []);

    const onRefresh = useCallback(() => {
        setRefreshing(true);
        fetchHistory();
    }, []);

    const formatDate = (dateStr) => {
        const d = new Date(dateStr);
        return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()} ${d.getHours()}:${String(d.getMinutes()).padStart(2, '0')}`;
    };

    const formatMoney = (value) => {
        return Math.round(value || 0).toLocaleString('vi-VN');
    };

    const openDetail = (item) => {
        setSelectedItem(item);
        setDetailVisible(true);
    };

    const renderItem = ({ item }) => (
        <TouchableOpacity style={styles.card} onPress={() => openDetail(item)}>
            <View style={styles.cardHeader}>
                <View style={styles.iconCircle}>
                    <User size={20} color={Colors.primary} />
                </View>
                <View style={styles.headerText}>
                    <Text style={styles.customerCode}>{item.customerCode || 'N/A'}</Text>
                    <Text style={styles.customerName}>{item.customerName}</Text>
                </View>
                <View style={styles.dateBadge}>
                    <Calendar size={12} color={Colors.textSecondary} style={{ marginRight: 4 }} />
                    <Text style={styles.date}>{formatDate(item.createdAt)}</Text>
                </View>
            </View>

            <View style={styles.divider} />

            <View style={styles.cardBody}>
                <View style={styles.amountCol}>
                    <Text style={styles.amountLabel}>Tổng đúng giá</Text>
                    <Text style={styles.amountSmall}>{formatMoney(item.totalDungGia)} đ</Text>
                </View>
                <View style={styles.amountCol}>
                    <Text style={styles.amountLabel}>Chênh lệch</Text>
                    <Text style={[styles.amountValue, { color: item.diff > 0 ? Colors.danger : Colors.success }]}>
                        {item.diff > 0 ? '+' : ''}{formatMoney(item.diff)} đ
                    </Text>
                </View>
                <ChevronRight size={20} color={Colors.border} />
            </View>
        </TouchableOpacity>
    );

    const renderDetailModal = () => {
        if (!selectedItem) return null;
        const details = selectedItem.details || {};

        return (
            <Modal
                visible={detailVisible}
                animationType="slide"
                presentationStyle="pageSheet"
            >
                <SafeAreaView style={styles.modalContainer}>
                    <View style={styles.modalHeader}>
                        <Text style={styles.modalTitle}>Chi tiết tính toán</Text>
                        <TouchableOpacity onPress={() => setDetailVisible(false)} style={styles.closeBtn}>
                            <X size={20} color={Colors.text} />
                        </TouchableOpacity>
                    </View>

                    <ScrollView contentContainerStyle={styles.modalScroll}>
                        {/* Customer Info */}
                        <View style={styles.detailCard}>
                            <View style={styles.detailHeader}>
                                <User size={18} color={Colors.primary} style={{ marginRight: 8 }} />
                                <Text style={styles.detailTitle}>Thông tin khách hàng</Text>
                            </View>
                            <View style={styles.detailRow}>
                                <Text style={styles.detailLabel}>Mã KH:</Text>
                                <Text style={styles.detailValue}>{selectedItem.customerCode || 'N/A'}</Text>
                            </View>
                            <View style={styles.detailRow}>
                                <Text style={styles.detailLabel}>Tên KH:</Text>
                                <Text style={styles.detailValue}>{selectedItem.customerName || 'N/A'}</Text>
                            </View>
                            <View style={styles.detailRow}>
                                <Text style={styles.detailLabel}>Ngày tính:</Text>
                                <Text style={styles.detailValue}>{formatDate(selectedItem.createdAt)}</Text>
                            </View>
                        </View>

                        {/* Summary */}
                        <View style={styles.detailCard}>
                            <View style={styles.detailHeader}>
                                <Calculator size={18} color={Colors.success} style={{ marginRight: 8 }} />
                                <Text style={styles.detailTitle}>Kết quả tổng hợp</Text>
                            </View>
                            <View style={styles.detailRow}>
                                <Text style={styles.detailLabel}>Tổng đúng giá:</Text>
                                <Text style={[styles.detailValue, { color: Colors.primary }]}>{formatMoney(details.tongTienDungGia)} đ</Text>
                            </View>
                            <View style={styles.detailRow}>
                                <Text style={styles.detailLabel}>Tổng đã tính:</Text>
                                <Text style={styles.detailValue}>{formatMoney(details.tongTienDaTinh)} đ</Text>
                            </View>
                            <View style={styles.detailRowHighlight}>
                                <Text style={styles.detailLabelBold}>CHÊNH LỆCH (TRUY THU):</Text>
                                <Text style={[styles.detailValueBold, { color: details.diff > 0 ? Colors.danger : Colors.success }]}>
                                    {details.diff > 0 ? '+' : ''}{formatMoney(details.diff)} đ
                                </Text>
                            </View>
                        </View>

                        {/* Monthly Breakdown */}
                        {details.chiTietTheoThang && details.chiTietTheoThang.length > 0 && (
                            <View style={styles.detailCard}>
                                <View style={styles.detailHeader}>
                                    <FileText size={18} color={Colors.warning} style={{ marginRight: 8 }} />
                                    <Text style={styles.detailTitle}>Chi tiết từng tháng</Text>
                                </View>
                                {details.chiTietTheoThang.map((month, idx) => (
                                    <View key={idx} style={styles.monthBlock}>
                                        <View style={styles.monthHeader}>
                                            <Text style={styles.monthName}>{month.tenThang}</Text>
                                            <Text style={styles.monthKwh}>{month.sanLuong} kWh</Text>
                                            <Text style={styles.monthPrice}>{formatMoney(month.tienDungGia)} đ</Text>
                                        </View>
                                        {month.chiTietBac && month.chiTietBac.map((bac, bIdx) => (
                                            <View key={bIdx} style={styles.bacRow}>
                                                <Text style={styles.bacLabel}>{bac.tenBac}</Text>
                                                <Text style={styles.bacKwh}>{Math.round(bac.kWh)} kWh</Text>
                                                <Text style={styles.bacPrice}>{formatMoney(bac.tien)} đ</Text>
                                            </View>
                                        ))}
                                        {idx < details.chiTietTheoThang.length - 1 && <View style={styles.monthDivider} />}
                                    </View>
                                ))}
                            </View>
                        )}

                        {/* Group Breakdown */}
                        {details.chiTietTienDungGia && details.chiTietTienDungGia.length > 0 && (
                            <View style={styles.detailCard}>
                                <View style={styles.detailHeader}>
                                    <CheckCircle2 size={18} color={Colors.secondary} style={{ marginRight: 8 }} />
                                    <Text style={styles.detailTitle}>Chi tiết theo nhóm giá</Text>
                                </View>
                                {details.chiTietTienDungGia.map((group, idx) => (
                                    <View key={idx} style={styles.groupRow}>
                                        <Text style={styles.groupName}>{group.tenNhom}</Text>
                                        <Text style={styles.groupKwh}>{Math.round(group.kWh)} kWh</Text>
                                        <Text style={styles.groupPrice}>{formatMoney(group.tongTien)} đ</Text>
                                    </View>
                                ))}
                            </View>
                        )}
                    </ScrollView>
                </SafeAreaView>
            </Modal>
        );
    };

    if (loading && !refreshing) {
        return (
            <View style={styles.centered}>
                <ActivityIndicator size="large" color={Colors.primary} />
            </View>
        );
    }

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <Text style={styles.headerTitle}>Lịch sử tính toán</Text>
            </View>
            <FlatList
                data={history}
                renderItem={renderItem}
                keyExtractor={item => item._id}
                contentContainerStyle={styles.list}
                refreshControl={
                    <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={Colors.primary} />
                }
                ListEmptyComponent={
                    <View style={styles.empty}>
                        <Clock size={60} color={Colors.border} />
                        <Text style={styles.emptyText}>Chưa có lịch sử nào</Text>
                        <TouchableOpacity style={styles.emptyBtn} onPress={onRefresh}>
                            <Text style={styles.emptyBtnText}>Tải lại</Text>
                        </TouchableOpacity>
                    </View>
                }
            />
            {renderDetailModal()}
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
    list: { padding: 16 },
    card: { backgroundColor: Colors.white, borderRadius: 16, padding: 16, marginBottom: 16, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 10, elevation: 2 },
    cardHeader: { flexDirection: 'row', alignItems: 'center' },
    iconCircle: { width: 40, height: 40, borderRadius: 20, backgroundColor: 'rgba(0,122,255,0.1)', justifyContent: 'center', alignItems: 'center' },
    headerText: { flex: 1, marginLeft: 12 },
    customerCode: { fontSize: 16, fontWeight: 'bold', color: Colors.text },
    customerName: { fontSize: 13, color: Colors.textSecondary },
    dateBadge: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#f5f5f5', paddingHorizontal: 8, paddingVertical: 4, borderRadius: 6 },
    date: { fontSize: 10, color: Colors.textSecondary },
    divider: { height: 1, backgroundColor: '#f0f0f0', marginVertical: 12 },
    cardBody: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
    amountCol: { flex: 1 },
    amountLabel: { fontSize: 10, color: Colors.textSecondary, marginBottom: 2 },
    amountSmall: { fontSize: 13, color: Colors.text, fontWeight: '500' },
    amountValue: { fontSize: 18, fontWeight: 'bold' },
    empty: { marginTop: 100, alignItems: 'center' },
    emptyText: { marginTop: 16, color: Colors.textSecondary, fontSize: 16 },
    emptyBtn: { marginTop: 20, paddingHorizontal: 20, paddingVertical: 10, backgroundColor: Colors.primary, borderRadius: 8 },
    emptyBtnText: { color: '#fff', fontWeight: 'bold' },
    centered: { flex: 1, justifyContent: 'center', alignItems: 'center' },

    // Modal Styles
    modalContainer: { flex: 1, backgroundColor: Colors.background },
    modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingHorizontal: 16, height: 56, backgroundColor: Colors.white, borderBottomWidth: 1, borderBottomColor: '#eee' },
    modalTitle: { fontSize: 18, fontWeight: 'bold' },
    closeBtn: { padding: 8, backgroundColor: '#f0f0f5', borderRadius: 20 },
    modalScroll: { padding: 16, paddingBottom: 40 },

    // Detail Card Styles
    detailCard: { backgroundColor: Colors.white, borderRadius: 16, padding: 16, marginBottom: 16 },
    detailHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 12 },
    detailTitle: { fontSize: 16, fontWeight: 'bold' },
    detailRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 },
    detailRowHighlight: { flexDirection: 'row', justifyContent: 'space-between', backgroundColor: '#f5f5f7', padding: 12, borderRadius: 8, marginTop: 8 },
    detailLabel: { fontSize: 14, color: Colors.textSecondary },
    detailValue: { fontSize: 14, fontWeight: '500' },
    detailLabelBold: { fontSize: 14, fontWeight: 'bold' },
    detailValueBold: { fontSize: 16, fontWeight: 'bold' },

    // Month Breakdown Styles
    monthBlock: { marginBottom: 8 },
    monthHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 6 },
    monthName: { fontWeight: 'bold', fontSize: 13, flex: 1 },
    monthKwh: { fontSize: 12, color: Colors.textSecondary, marginRight: 12 },
    monthPrice: { fontSize: 13, fontWeight: '600', color: Colors.primary },
    bacRow: { flexDirection: 'row', paddingLeft: 12, marginBottom: 4 },
    bacLabel: { flex: 1.5, fontSize: 11, color: Colors.textSecondary },
    bacKwh: { flex: 1, fontSize: 11, textAlign: 'right' },
    bacPrice: { flex: 1, fontSize: 11, textAlign: 'right', color: Colors.text },
    monthDivider: { height: 1, backgroundColor: '#f0f0f0', marginVertical: 8 },

    // Group Breakdown Styles
    groupRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8, paddingVertical: 8, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: '#eee' },
    groupName: { flex: 1, fontSize: 13, fontWeight: '600' },
    groupKwh: { fontSize: 12, color: Colors.textSecondary, marginRight: 16 },
    groupPrice: { fontSize: 13, fontWeight: '500', color: Colors.primary }
});
