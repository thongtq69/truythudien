import React, { useState, useMemo, useEffect } from 'react';
import { StyleSheet, View, Text, ScrollView, TextInput, TouchableOpacity, Alert, SafeAreaView, LayoutAnimation } from 'react-native';
import { Colors } from '../theme/colors';
import { ElectricityCalculationService } from '../services/calculationService';
import api from '../api/network';
import { Save, Plus, Trash2, Calculator, RotateCcw, Info, FileText, CheckCircle2, ChevronRight, ChevronDown, Calendar, Clock } from 'lucide-react-native';
import Stepper from '../components/Stepper';
import Collapsible from '../components/Collapsible';
import ProportionRow from '../components/ProportionRow';
import MonthSelector from '../components/MonthSelector';
import PriceInfoScreen from './PriceInfoScreen';
import { Modal } from 'react-native';
import { useSettings, PRICE_PERIODS } from '../context/SettingsContext';

const MONTH_NAMES = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];

const DEFAULT_MONTH = (index) => ({
    id: Math.random().toString(),
    name: `Tháng ${index + 1}`,
    consumption: '0',
    otherFee: '0',
    tyLeReality: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 },
    tyLeApplied: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 }
});

export default function CalculatorScreen({ navigation }) {
    const { prices, selectedPeriod, selectPeriod, suggestPeriod, getPricesForPeriod, PRICE_PERIODS } = useSettings();
    const [calcMode, setCalcMode] = useState('single'); // 'single' or 'year'
    const [customerCode, setCustomerCode] = useState('');
    const [customerName, setCustomerName] = useState('');
    const [soHoApplied, setSoHoApplied] = useState(1);
    const [soHoReality, setSoHoReality] = useState(1);
    const [months, setMonths] = useState([DEFAULT_MONTH(0)]);
    const [result, setResult] = useState(null);
    const [showPriceInfo, setShowPriceInfo] = useState(false);

    // Year mode states
    const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());
    const [selectedMonths, setSelectedMonths] = useState([]);
    const [yearlyMonthData, setYearlyMonthData] = useState({}); // { monthIndex: { consumption, otherFee, tyLeApplied, tyLeReality } }

    // Auto-suggest period when year changes in year mode
    useEffect(() => {
        if (calcMode === 'year' && selectedMonths.length > 0) {
            // Use the first selected month to suggest period
            const suggestedPeriod = suggestPeriod(selectedYear, selectedMonths[0]);
            if (suggestedPeriod !== selectedPeriod) {
                selectPeriod(suggestedPeriod);
            }
        }
    }, [selectedYear, selectedMonths, calcMode]);

    const DEFAULT_YEARLY_MONTH = () => ({
        consumption: '',
        otherFee: '0',
        tyLeApplied: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 },
        tyLeReality: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 }
    });

    const initYearlyMonth = (mIdx) => {
        if (!yearlyMonthData[mIdx]) {
            setYearlyMonthData(prev => ({ ...prev, [mIdx]: DEFAULT_YEARLY_MONTH() }));
        }
    };

    const updateYearlyMonthField = (mIdx, field, value) => {
        setYearlyMonthData(prev => ({
            ...prev,
            [mIdx]: { ...(prev[mIdx] || DEFAULT_YEARLY_MONTH()), [field]: value }
        }));
    };

    const updateYearlyMonthRatio = (mIdx, ratioType, field, value) => {
        setYearlyMonthData(prev => {
            const monthData = prev[mIdx] || DEFAULT_YEARLY_MONTH();
            return {
                ...prev,
                [mIdx]: {
                    ...monthData,
                    [ratioType]: { ...monthData[ratioType], [field]: value }
                }
            };
        });
    };

    const tongSanLuong = useMemo(() => {
        if (calcMode === 'year') {
            return selectedMonths.reduce((sum, mIdx) => {
                const data = yearlyMonthData[mIdx];
                return sum + (parseFloat(data?.consumption) || 0);
            }, 0);
        }
        return months.reduce((sum, m) => sum + (parseFloat(m.consumption) || 0), 0);
    }, [months, calcMode, selectedMonths, yearlyMonthData]);

    const tongPhiKhac = useMemo(() => {
        if (calcMode === 'year') {
            return selectedMonths.reduce((sum, mIdx) => {
                const data = yearlyMonthData[mIdx];
                return sum + (parseFloat(data?.otherFee) || 0);
            }, 0);
        }
        return months.reduce((sum, m) => sum + (parseFloat(m.otherFee) || 0), 0);
    }, [months, calcMode, selectedMonths, yearlyMonthData]);

    const calculate = () => {
        const calcService = new ElectricityCalculationService(prices);

        let monthsData;
        if (calcMode === 'year') {
            if (selectedMonths.length === 0) {
                Alert.alert('Lỗi', 'Vui lòng chọn ít nhất 1 tháng');
                return;
            }
            monthsData = selectedMonths.map(mIdx => {
                const data = yearlyMonthData[mIdx] || DEFAULT_YEARLY_MONTH();
                return {
                    id: Math.random().toString(),
                    name: MONTH_NAMES[mIdx],
                    consumption: parseFloat(data.consumption) || 0,
                    otherFee: parseFloat(data.otherFee) || 0,
                    tyLeApplied: data.tyLeApplied,
                    tyLeReality: data.tyLeReality
                };
            });
        } else {
            monthsData = months.map(m => ({
                ...m,
                consumption: parseFloat(m.consumption) || 0,
                otherFee: parseFloat(m.otherFee) || 0
            }));
        }

        const info = {
            maKhachHang: customerCode,
            soHoApplied: soHoApplied,
            soHoReality: soHoReality,
            months: monthsData
        };
        const res = calcService.tinhChenhLech(info);
        setResult(res);
    };

    const handleSave = async () => {
        if (!result) return;
        try {
            await api.post('/calculations', {
                customerName: customerName || 'Chưa có tên',
                customerCode: customerCode,
                totalDungGia: result.tongTienDungGia,
                totalDaTinh: result.tongTienDaTinh,
                diff: result.diff,
                details: result
            });
            Alert.alert('Thành công', 'Đã lưu kết quả tính toán');
        } catch (error) {
            Alert.alert('Lỗi', 'Không thể lưu kết quả');
        }
    };

    const addMonth = () => {
        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        setMonths([...months, DEFAULT_MONTH(months.length)]);
    };

    const removeMonth = (id) => {
        if (months.length <= 1) return;
        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        setMonths(months.filter(m => m.id !== id));
    };

    const reset = () => {
        setCustomerCode('');
        setCustomerName('');
        setSoHoApplied(1);
        setSoHoReality(1);
        setMonths([DEFAULT_MONTH(0)]);
        setResult(null);
        // Reset year mode
        setSelectedMonths([]);
        setYearlyMonthData({});
    };

    const loadSample = () => {
        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        setCustomerCode('KH123456');
        setCustomerName('Nguyễn Văn A');
        setSoHoApplied(1);
        setSoHoReality(1);
        setMonths([
            {
                id: Math.random().toString(),
                name: 'Tháng 1',
                consumption: '350',
                otherFee: '0',
                tyLeReality: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 },
                tyLeApplied: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 }
            }
        ]);
    };

    const updateMonthRatio = (monthId, type, field, val) => {
        setMonths(months.map(m => {
            if (m.id === monthId) {
                return {
                    ...m,
                    [type]: { ...m[type], [field]: val }
                };
            }
            return m;
        }));
    };

    const getTongTyLe = (tyLe) => {
        return Object.values(tyLe).reduce((a, b) => a + b, 0);
    };

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.topBar}>
                <TouchableOpacity onPress={loadSample}>
                    <Text style={styles.topBarBtn}>Mẫu</Text>
                </TouchableOpacity>
                <Text style={styles.topBarTitle}>Truy Thu Điện</Text>
                <TouchableOpacity onPress={() => setShowPriceInfo(true)}>
                    <Info size={22} color={Colors.primary} />
                </TouchableOpacity>

                <Modal
                    visible={showPriceInfo}
                    animationType="slide"
                    presentationStyle="pageSheet"
                >
                    <PriceInfoScreen onClose={() => setShowPriceInfo(false)} />
                </Modal>
            </View>

            <ScrollView contentContainerStyle={styles.scroll}>
                <View style={styles.card}>
                    <View style={styles.sectionHeader}>
                        <FileText size={18} color={Colors.text} style={{ marginRight: 8 }} />
                        <Text style={styles.sectionTitle}>Thông tin định mức & Hợp đồng</Text>
                    </View>

                    <TextInput
                        style={styles.input}
                        placeholder="Mã khách hàng"
                        value={customerCode}
                        onChangeText={setCustomerCode}
                        placeholderTextColor={Colors.textSecondary}
                    />

                    <View style={styles.stepperRow}>
                        <Stepper
                            label="Số hộ đăng ký"
                            value={soHoApplied}
                            onValueChange={setSoHoApplied}
                        />
                        <View style={styles.vDivider} />
                        <Stepper
                            label="Số hộ thực tế"
                            value={soHoReality}
                            onValueChange={setSoHoReality}
                        />
                    </View>

                    <View style={styles.divider} />

                    {/* Price Period Selector */}
                    <View style={styles.periodSection}>
                        <View style={styles.periodHeader}>
                            <Clock size={16} color={Colors.primary} />
                            <Text style={styles.periodLabel}>Thời kỳ áp dụng giá:</Text>
                        </View>
                        <View style={styles.periodButtons}>
                            {Object.values(PRICE_PERIODS).map((period) => (
                                <TouchableOpacity
                                    key={period.id}
                                    style={[
                                        styles.periodBtn,
                                        selectedPeriod === period.id && styles.periodBtnActive
                                    ]}
                                    onPress={() => selectPeriod(period.id)}
                                >
                                    <Text style={[
                                        styles.periodBtnText,
                                        selectedPeriod === period.id && styles.periodBtnTextActive
                                    ]}>
                                        {period.shortName}
                                    </Text>
                                </TouchableOpacity>
                            ))}
                        </View>
                    </View>

                    <View style={styles.divider} />

                    {/* Mode Toggle */}
                    <View style={styles.modeToggleRow}>
                        <TouchableOpacity
                            style={[styles.modeBtn, calcMode === 'single' && styles.modeBtnActive]}
                            onPress={() => setCalcMode('single')}
                        >
                            <FileText size={16} color={calcMode === 'single' ? '#fff' : Colors.textSecondary} />
                            <Text style={[styles.modeBtnText, calcMode === 'single' && styles.modeBtnTextActive]}>Tùy chọn</Text>
                        </TouchableOpacity>
                        <TouchableOpacity
                            style={[styles.modeBtn, calcMode === 'year' && styles.modeBtnActive]}
                            onPress={() => setCalcMode('year')}
                        >
                            <Calendar size={16} color={calcMode === 'year' ? '#fff' : Colors.textSecondary} />
                            <Text style={[styles.modeBtnText, calcMode === 'year' && styles.modeBtnTextActive]}>Theo năm</Text>
                        </TouchableOpacity>
                    </View>

                    <View style={styles.divider} />

                    {calcMode === 'year' ? (
                        <>
                            {/* Year Picker for Year Mode */}
                            <View style={styles.yearPickerRow}>
                                <Text style={styles.yearLabel}>Năm tính toán:</Text>
                                <View style={styles.yearStepper}>
                                    <TouchableOpacity
                                        style={styles.yearBtn}
                                        onPress={() => setSelectedYear(y => Math.max(2020, y - 1))}
                                    >
                                        <Text style={styles.yearBtnText}>−</Text>
                                    </TouchableOpacity>
                                    <Text style={styles.yearValue}>{selectedYear}</Text>
                                    <TouchableOpacity
                                        style={styles.yearBtn}
                                        onPress={() => setSelectedYear(y => Math.min(2030, y + 1))}
                                    >
                                        <Text style={styles.yearBtnText}>+</Text>
                                    </TouchableOpacity>
                                </View>
                            </View>

                            <Text style={styles.subSectionTitle}>Chọn các tháng tính toán</Text>
                            <MonthSelector
                                selectedMonths={selectedMonths}
                                onSelectionChange={(newSelection) => {
                                    setSelectedMonths(newSelection);
                                    // Initialize data for newly selected months
                                    newSelection.forEach(mIdx => {
                                        if (!yearlyMonthData[mIdx]) {
                                            setYearlyMonthData(prev => ({
                                                ...prev,
                                                [mIdx]: {
                                                    consumption: '',
                                                    otherFee: '0',
                                                    tyLeApplied: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 },
                                                    tyLeReality: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 }
                                                }
                                            }));
                                        }
                                    });
                                }}
                            />

                            {selectedMonths.length > 0 && (
                                <>
                                    <Text style={styles.subSectionTitle}>Chi tiết từng tháng</Text>
                                    {selectedMonths.map(mIdx => {
                                        const monthData = yearlyMonthData[mIdx] || {
                                            consumption: '',
                                            otherFee: '0',
                                            tyLeApplied: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 },
                                            tyLeReality: { tyLeSinhHoat: 1, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0 }
                                        };
                                        return (
                                            <View key={mIdx} style={styles.monthCard}>
                                                <Text style={styles.monthName}>{MONTH_NAMES[mIdx]}</Text>

                                                <View style={styles.consumptionRow}>
                                                    <View style={styles.flex1}>
                                                        <Text style={styles.miniLabel}>Sản lượng (kWh)</Text>
                                                        <TextInput
                                                            style={styles.inputSmall}
                                                            keyboardType="numeric"
                                                            placeholder="0"
                                                            value={String(monthData.consumption || '')}
                                                            onChangeText={(val) => updateYearlyMonthField(mIdx, 'consumption', val)}
                                                        />
                                                    </View>
                                                    <View style={styles.hSpacer} />
                                                    <View style={styles.flex1}>
                                                        <Text style={styles.miniLabel}>Phí khác (đ)</Text>
                                                        <TextInput
                                                            style={styles.inputSmall}
                                                            keyboardType="numeric"
                                                            placeholder="0"
                                                            value={String(monthData.otherFee || '')}
                                                            onChangeText={(val) => updateYearlyMonthField(mIdx, 'otherFee', val)}
                                                        />
                                                    </View>
                                                </View>

                                                <Collapsible
                                                    label="Tỷ lệ áp dụng (Hệ thống)"
                                                    isWarning={Math.abs(getTongTyLe(monthData.tyLeApplied) - 1) > 0.001}
                                                >
                                                    <ProportionRow label="SHBT" value={monthData.tyLeApplied.tyLeSinhHoat} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeApplied', 'tyLeSinhHoat', val)} />
                                                    <ProportionRow label="SXBT" value={monthData.tyLeApplied.tyLeSanXuat} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeApplied', 'tyLeSanXuat', val)} />
                                                    <ProportionRow label="KDDV" value={monthData.tyLeApplied.tyLeKinhDoanh} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeApplied', 'tyLeKinhDoanh', val)} />
                                                    <ProportionRow label="HCSN(BV)" value={monthData.tyLeApplied.tyLeHCSNBenhVien} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeApplied', 'tyLeHCSNBenhVien', val)} />
                                                    <ProportionRow label="HCSN(CS)" value={monthData.tyLeApplied.tyLeHCSNChieuSang} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeApplied', 'tyLeHCSNChieuSang', val)} />
                                                </Collapsible>

                                                <Collapsible
                                                    label="Tỷ lệ thực tế (Kiểm tra)"
                                                    isWarning={Math.abs(getTongTyLe(monthData.tyLeReality) - 1) > 0.001}
                                                >
                                                    <ProportionRow label="SHBT" value={monthData.tyLeReality.tyLeSinhHoat} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeReality', 'tyLeSinhHoat', val)} />
                                                    <ProportionRow label="SXBT" value={monthData.tyLeReality.tyLeSanXuat} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeReality', 'tyLeSanXuat', val)} />
                                                    <ProportionRow label="KDDV" value={monthData.tyLeReality.tyLeKinhDoanh} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeReality', 'tyLeKinhDoanh', val)} />
                                                    <ProportionRow label="HCSN(BV)" value={monthData.tyLeReality.tyLeHCSNBenhVien} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeReality', 'tyLeHCSNBenhVien', val)} />
                                                    <ProportionRow label="HCSN(CS)" value={monthData.tyLeReality.tyLeHCSNChieuSang} onValueChange={(val) => updateYearlyMonthRatio(mIdx, 'tyLeReality', 'tyLeHCSNChieuSang', val)} />
                                                </Collapsible>
                                            </View>
                                        );
                                    })}
                                </>
                            )}
                        </>
                    ) : (
                        <>
                            <View style={styles.monthHeaderRow}>
                                <Text style={styles.subSectionTitle}>Danh sách tháng tính toán</Text>
                                <TouchableOpacity style={styles.addMonthBtn} onPress={addMonth}>
                                    <View style={styles.plusCircle}>
                                        <Plus size={14} color="#fff" />
                                    </View>
                                    <Text style={styles.addMonthText}>Thêm tháng</Text>
                                </TouchableOpacity>
                            </View>

                            {months.map((m, idx) => (
                                <View key={m.id} style={styles.monthCard}>
                                    <View style={styles.monthCardHeader}>
                                        <Text style={styles.monthName}>{m.name}</Text>
                                        {months.length > 1 && (
                                            <TouchableOpacity onPress={() => removeMonth(m.id)}>
                                                <Trash2 size={16} color={Colors.danger} />
                                            </TouchableOpacity>
                                        )}
                                    </View>

                                    <View style={styles.consumptionRow}>
                                        <View style={styles.flex1}>
                                            <Text style={styles.miniLabel}>Sản lượng (kWh)</Text>
                                            <TextInput
                                                style={styles.inputSmall}
                                                keyboardType="numeric"
                                                value={m.consumption}
                                                onChangeText={(val) => {
                                                    let newMonths = [...months];
                                                    newMonths[idx].consumption = val;
                                                    setMonths(newMonths);
                                                }}
                                            />
                                        </View>
                                        <View style={styles.hSpacer} />
                                        <View style={styles.flex1}>
                                            <Text style={styles.miniLabel}>Phí khác (đ)</Text>
                                            <TextInput
                                                style={styles.inputSmall}
                                                keyboardType="numeric"
                                                value={m.otherFee}
                                                onChangeText={(val) => {
                                                    let newMonths = [...months];
                                                    newMonths[idx].otherFee = val;
                                                    setMonths(newMonths);
                                                }}
                                            />
                                        </View>
                                    </View>

                                    <Collapsible
                                        label="Tỷ lệ đang áp dụng (Hệ thống)"
                                        isWarning={Math.abs(getTongTyLe(m.tyLeApplied) - 1) > 0.001}
                                    >
                                        <ProportionRow label="SHBT" value={m.tyLeApplied.tyLeSinhHoat} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeApplied', 'tyLeSinhHoat', val)} />
                                        <ProportionRow label="SXBT" value={m.tyLeApplied.tyLeSanXuat} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeApplied', 'tyLeSanXuat', val)} />
                                        <ProportionRow label="KDDV" value={m.tyLeApplied.tyLeKinhDoanh} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeApplied', 'tyLeKinhDoanh', val)} />
                                        <ProportionRow label="HCSN(BV)" value={m.tyLeApplied.tyLeHCSNBenhVien} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeApplied', 'tyLeHCSNBenhVien', val)} />
                                        <ProportionRow label="HCSN(CS)" value={m.tyLeApplied.tyLeHCSNChieuSang} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeApplied', 'tyLeHCSNChieuSang', val)} />

                                        <View style={styles.totalRatioRow}>
                                            <Text style={styles.totalRatioLabel}>Tổng tỷ lệ áp dụng</Text>
                                            <Text style={[styles.totalRatioValue, { color: Math.abs(getTongTyLe(m.tyLeApplied) - 1) < 0.001 ? Colors.success : Colors.danger }]}>
                                                {Math.round(getTongTyLe(m.tyLeApplied) * 100)}%
                                            </Text>
                                        </View>
                                    </Collapsible>

                                    <Collapsible
                                        label="Tỷ lệ sử dụng thực tế (Kiểm tra)"
                                        isWarning={Math.abs(getTongTyLe(m.tyLeReality) - 1) > 0.001}
                                    >
                                        <ProportionRow label="SHBT" value={m.tyLeReality.tyLeSinhHoat} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeReality', 'tyLeSinhHoat', val)} />
                                        <ProportionRow label="SXBT" value={m.tyLeReality.tyLeSanXuat} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeReality', 'tyLeSanXuat', val)} />
                                        <ProportionRow label="KDDV" value={m.tyLeReality.tyLeKinhDoanh} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeReality', 'tyLeKinhDoanh', val)} />
                                        <ProportionRow label="HCSN(BV)" value={m.tyLeReality.tyLeHCSNBenhVien} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeReality', 'tyLeHCSNBenhVien', val)} />
                                        <ProportionRow label="HCSN(CS)" value={m.tyLeReality.tyLeHCSNChieuSang} onValueChange={(val) => updateMonthRatio(m.id, 'tyLeReality', 'tyLeHCSNChieuSang', val)} />

                                        <View style={styles.totalRatioRow}>
                                            <Text style={styles.totalRatioLabel}>Tổng tỷ lệ thực tế</Text>
                                            <Text style={[styles.totalRatioValue, { color: Math.abs(getTongTyLe(m.tyLeReality) - 1) < 0.001 ? Colors.success : Colors.danger }]}>
                                                {Math.round(getTongTyLe(m.tyLeReality) * 100)}%
                                            </Text>
                                        </View>
                                    </Collapsible>
                                </View>
                            ))}

                            <View style={styles.divider} />

                            <View style={styles.summaryRow}>
                                <View>
                                    <Text style={styles.summaryLabel}>TỔNG SẢN LƯỢNG:</Text>
                                    <Text style={styles.summaryValueBlue}>{tongSanLuong.toLocaleString()} kWh</Text>
                                </View>
                                <View style={styles.alignEnd}>
                                    <Text style={styles.summaryLabel}>TỔNG PHÍ KHÁC:</Text>
                                    <Text style={styles.summaryValueOrange}>{tongPhiKhac.toLocaleString()} đ</Text>
                                </View>
                            </View>
                        </>
                    )}
                </View>

                <View style={styles.buttonRow}>
                    <TouchableOpacity
                        style={[styles.calcBtn, tongSanLuong === 0 && styles.btnDisabled]}
                        onPress={calculate}
                        disabled={tongSanLuong === 0}
                    >
                        <Calculator size={20} color="#fff" />
                        <Text style={styles.calcBtnText}>Tính toán</Text>
                    </TouchableOpacity>
                    <TouchableOpacity style={styles.resetBtn} onPress={reset}>
                        <RotateCcw size={20} color={Colors.text} />
                        <Text style={styles.resetBtnText}>Làm mới</Text>
                    </TouchableOpacity>
                </View>

                {result && (
                    <View style={styles.resultCard}>
                        <View style={styles.sectionHeader}>
                            <CheckCircle2 size={18} color={Colors.success} style={{ marginRight: 8 }} />
                            <Text style={[styles.sectionTitle, { color: Colors.success }]}>Kết quả tính toán</Text>
                            <TouchableOpacity style={styles.saveBtn} onPress={handleSave}>
                                <Save size={16} color={Colors.primary} />
                                <Text style={styles.saveBtnText}>Lưu lại</Text>
                            </TouchableOpacity>
                        </View>

                        <View style={styles.resRow}>
                            <Text style={styles.resLabel}>Tiền đã tính (sai giá)</Text>
                            <Text style={styles.resValueOrange}>{Math.round(result.tongTienDaTinh).toLocaleString()} đ</Text>
                        </View>
                        <View style={styles.resRow}>
                            <Text style={styles.resLabel}>Tiền đúng giá</Text>
                            <Text style={styles.resValueGreen}>{Math.round(result.tongTienDungGia).toLocaleString()} đ</Text>
                        </View>

                        <View style={styles.divider} />

                        <View style={styles.finalRow}>
                            <Text style={styles.finalLabel}>CHÊNH LỆCH / TRUY THU</Text>
                            <Text style={[styles.finalValue, { color: result.diff > 0 ? Colors.danger : Colors.primary }]}>
                                {Math.round(result.diff).toLocaleString()} đ
                            </Text>
                        </View>

                        <Text style={[styles.noteText, { color: result.diff > 0 ? Colors.danger : Colors.primary }]}>
                            {result.diff > 0
                                ? `Số tiền truy thu: ${Math.round(result.diff).toLocaleString()} đ`
                                : `Ngành điện cần hoàn trả: ${Math.round(Math.abs(result.diff)).toLocaleString()} đ`}
                        </Text>

                        {result.chiTietTheoThang.length > 0 && (
                            <View style={styles.reportSection}>
                                <Text style={styles.reportTitle}>Báo cáo chi tiết từng tháng</Text>
                                {result.chiTietTheoThang.map(m => (
                                    <View key={m.id} style={styles.monthReportItem}>
                                        <View style={styles.monthReportHeader}>
                                            <Text style={styles.mReportName}>{m.tenThang}:</Text>
                                            <View style={styles.row}>
                                                <Text style={styles.mReportKwh}>{m.sanLuong} kWh</Text>
                                                <Text style={styles.mReportPrice}>{Math.round(m.tienDungGia).toLocaleString()} đ</Text>
                                            </View>
                                        </View>
                                        {m.chiTietBac.map((bac, bIdx) => (
                                            bac.kWh > 0 && (
                                                <View key={bIdx} style={styles.bacRow}>
                                                    <Text style={styles.bacLabel}>{bac.tenBac}</Text>
                                                    <Text style={styles.bacKwh}>{bac.kWh} kWh</Text>
                                                    <Text style={styles.bacPrice}>{Math.round(bac.tien).toLocaleString()} đ</Text>
                                                </View>
                                            )
                                        ))}
                                        <View style={styles.mDivider} />
                                    </View>
                                ))}
                            </View>
                        )}
                    </View>
                )}
            </ScrollView>
        </SafeAreaView>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: Colors.white },
    topBar: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingHorizontal: 16,
        height: 56,
        borderBottomWidth: 1,
        borderBottomColor: '#eee'
    },
    topBarTitle: { fontSize: 18, fontWeight: 'bold' },
    topBarBtn: { color: Colors.primary, fontSize: 16 },
    scroll: { padding: 16, backgroundColor: Colors.background },
    card: { backgroundColor: '#F9F9F9', borderRadius: 16, padding: 16, marginBottom: 16 },
    sectionHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 16 },
    sectionTitle: { fontSize: 16, fontWeight: 'bold' },
    input: { backgroundColor: Colors.white, height: 44, borderRadius: 8, paddingHorizontal: 12, marginBottom: 16, borderWidth: 1, borderColor: '#eee' },
    stepperRow: { flexDirection: 'row', alignItems: 'center', marginVertical: 8 },
    vDivider: { width: 1, height: 40, backgroundColor: '#ddd', marginHorizontal: 15 },
    divider: { height: 1, backgroundColor: '#eee', marginVertical: 16 },
    monthHeaderRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
    subSectionTitle: { fontSize: 14, fontWeight: 'bold' },
    addMonthBtn: { flexDirection: 'row', alignItems: 'center' },
    plusCircle: { width: 18, height: 18, borderRadius: 9, backgroundColor: Colors.success, justifyContent: 'center', alignItems: 'center', marginRight: 6 },
    addMonthText: { fontSize: 12, color: Colors.textSecondary },
    monthCard: { backgroundColor: Colors.white, borderRadius: 12, padding: 16, marginBottom: 12, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 2, elevation: 1 },
    monthCardHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 },
    monthName: { fontSize: 14, fontWeight: 'bold' },
    consumptionRow: { flexDirection: 'row', marginBottom: 12 },
    flex1: { flex: 1 },
    hSpacer: { width: 12 },
    miniLabel: { fontSize: 10, color: Colors.textSecondary, marginBottom: 4 },
    inputSmall: { backgroundColor: Colors.white, height: 36, borderRadius: 6, paddingHorizontal: 8, borderWidth: 1, borderColor: '#eee', fontSize: 14 },
    summaryRow: { flexDirection: 'row', justifyContent: 'space-between' },
    summaryLabel: { fontSize: 10, color: Colors.textSecondary, marginBottom: 2 },
    summaryValueBlue: { fontSize: 16, fontWeight: 'bold', color: Colors.primary },
    summaryValueOrange: { fontSize: 16, fontWeight: 'bold', color: Colors.warning },
    alignEnd: { alignItems: 'flex-end' },
    buttonRow: { flexDirection: 'row', gap: 12, marginBottom: 24 },
    calcBtn: { flex: 2, backgroundColor: Colors.primary, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', height: 48, borderRadius: 10 },
    calcBtnText: { color: '#fff', fontSize: 16, fontWeight: 'bold', marginLeft: 8 },
    resetBtn: { flex: 1, backgroundColor: '#eee', flexDirection: 'row', alignItems: 'center', justifyContent: 'center', height: 48, borderRadius: 10 },
    resetBtnText: { color: Colors.text, fontSize: 16, fontWeight: 'bold', marginLeft: 8 },
    btnDisabled: { opacity: 0.5 },
    resultCard: { backgroundColor: '#F9F9F9', borderRadius: 16, padding: 16, marginBottom: 30 },
    saveBtn: { flexDirection: 'row', alignItems: 'center', marginLeft: 'auto', borderWidth: 1, borderColor: Colors.primary, borderRadius: 6, paddingHorizontal: 8, paddingVertical: 4 },
    saveBtnText: { fontSize: 12, color: Colors.primary, marginLeft: 4 },
    resRow: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 8 },
    resLabel: { fontSize: 14, color: Colors.textSecondary },
    resValueOrange: { fontSize: 14, color: Colors.warning, fontWeight: '500' },
    resValueGreen: { fontSize: 14, color: Colors.success, fontWeight: '500' },
    finalRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 8 },
    finalLabel: { fontSize: 16, fontWeight: 'bold' },
    finalValue: { fontSize: 24, fontWeight: 'bold' },
    noteText: { fontSize: 14, marginTop: 8 },
    reportSection: { marginTop: 16, backgroundColor: 'rgba(0,122,255,0.05)', borderRadius: 8, padding: 12 },
    reportTitle: { fontSize: 14, fontWeight: 'bold', color: Colors.primary, marginBottom: 12 },
    monthReportItem: { marginBottom: 12 },
    monthReportHeader: { flexDirection: 'row', justifyContent: 'space-between', marginBottom: 6 },
    mReportName: { fontWeight: 'bold', fontSize: 12 },
    mReportKwh: { fontSize: 12, marginRight: 8 },
    mReportPrice: { fontSize: 12, color: Colors.primary, fontWeight: '500' },
    bacRow: { flexDirection: 'row', paddingLeft: 10, marginBottom: 4 },
    bacLabel: { flex: 1.5, fontSize: 9, color: Colors.textSecondary },
    bacKwh: { flex: 1, fontSize: 9, textAlign: 'right' },
    bacPrice: { flex: 1, fontSize: 9, textAlign: 'right' },
    mDivider: { height: 1, backgroundColor: 'rgba(0,0,0,0.05)', marginTop: 8 },
    row: { flexDirection: 'row' },
    totalRatioRow: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 8, paddingTop: 8, borderTopWidth: StyleSheet.hairlineWidth, borderTopColor: '#eee' },
    totalRatioLabel: { fontSize: 10, fontWeight: 'bold', color: Colors.textSecondary },
    totalRatioValue: { fontSize: 10, fontWeight: 'bold' },
    // Mode toggle styles
    modeToggleRow: { flexDirection: 'row', justifyContent: 'center', gap: 12 },
    modeBtn: { flexDirection: 'row', alignItems: 'center', paddingHorizontal: 16, paddingVertical: 10, borderRadius: 20, backgroundColor: '#f0f0f5' },
    modeBtnActive: { backgroundColor: Colors.primary },
    modeBtnText: { fontSize: 13, color: Colors.textSecondary, marginLeft: 6, fontWeight: '500' },
    modeBtnTextActive: { color: '#fff' },
    // Yearly input styles
    yearlyInputGrid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', marginBottom: 12 },
    yearlyInputItem: { width: '32%', marginBottom: 10 },
    yearlyMonthLabel: { fontSize: 11, color: Colors.textSecondary, marginBottom: 4, textAlign: 'center' },
    yearlyInput: { backgroundColor: Colors.white, height: 36, borderRadius: 8, paddingHorizontal: 8, borderWidth: 1, borderColor: '#ddd', fontSize: 14, textAlign: 'center' },
    // Period selector styles
    periodSection: { marginBottom: 4 },
    periodHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 10 },
    periodLabel: { fontSize: 13, fontWeight: '600', marginLeft: 6, color: Colors.text },
    periodButtons: { flexDirection: 'row', gap: 10 },
    periodBtn: { flex: 1, paddingVertical: 10, paddingHorizontal: 12, backgroundColor: '#f0f0f5', borderRadius: 10, alignItems: 'center', borderWidth: 2, borderColor: 'transparent' },
    periodBtnActive: { backgroundColor: 'rgba(0,122,255,0.1)', borderColor: Colors.primary },
    periodBtnText: { fontSize: 13, color: Colors.textSecondary, fontWeight: '500' },
    periodBtnTextActive: { color: Colors.primary, fontWeight: 'bold' },
    // Year picker styles
    yearPickerRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16, backgroundColor: '#f5f5f7', padding: 12, borderRadius: 10 },
    yearLabel: { fontSize: 14, fontWeight: '600' },
    yearStepper: { flexDirection: 'row', alignItems: 'center' },
    yearBtn: { width: 36, height: 36, borderRadius: 18, backgroundColor: Colors.primary, justifyContent: 'center', alignItems: 'center' },
    yearBtnText: { fontSize: 20, color: '#fff', fontWeight: 'bold' },
    yearValue: { fontSize: 20, fontWeight: 'bold', marginHorizontal: 20, color: Colors.primary }
});
