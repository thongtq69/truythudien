import React, { useState } from 'react';
import { StyleSheet, View, Text, TouchableOpacity, ScrollView } from 'react-native';
import { Colors } from '../theme/colors';
import { Check } from 'lucide-react-native';

const MONTH_NAMES = [
    'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
    'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
    'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
];

const MonthSelector = ({ selectedMonths, onSelectionChange }) => {
    const toggleMonth = (monthIndex) => {
        if (selectedMonths.includes(monthIndex)) {
            onSelectionChange(selectedMonths.filter(m => m !== monthIndex));
        } else {
            onSelectionChange([...selectedMonths, monthIndex].sort((a, b) => a - b));
        }
    };

    const selectAll = () => {
        onSelectionChange([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
    };

    const clearAll = () => {
        onSelectionChange([]);
    };

    const selectQuarter = (quarter) => {
        const quarters = {
            1: [0, 1, 2],
            2: [3, 4, 5],
            3: [6, 7, 8],
            4: [9, 10, 11]
        };
        onSelectionChange(quarters[quarter]);
    };

    const selectHalf = (half) => {
        const halves = {
            1: [0, 1, 2, 3, 4, 5],
            2: [6, 7, 8, 9, 10, 11]
        };
        onSelectionChange(halves[half]);
    };

    return (
        <View style={styles.container}>
            <View style={styles.quickSelectRow}>
                <TouchableOpacity style={styles.quickBtn} onPress={selectAll}>
                    <Text style={styles.quickBtnText}>Cả năm</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.quickBtn} onPress={() => selectHalf(1)}>
                    <Text style={styles.quickBtnText}>6T đầu</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.quickBtn} onPress={() => selectHalf(2)}>
                    <Text style={styles.quickBtnText}>6T cuối</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.quickBtn} onPress={clearAll}>
                    <Text style={[styles.quickBtnText, { color: Colors.danger }]}>Bỏ chọn</Text>
                </TouchableOpacity>
            </View>

            <View style={styles.quarterRow}>
                {[1, 2, 3, 4].map(q => (
                    <TouchableOpacity
                        key={q}
                        style={styles.quarterBtn}
                        onPress={() => selectQuarter(q)}
                    >
                        <Text style={styles.quarterText}>Q{q}</Text>
                    </TouchableOpacity>
                ))}
            </View>

            <View style={styles.monthGrid}>
                {MONTH_NAMES.map((name, idx) => {
                    const isSelected = selectedMonths.includes(idx);
                    return (
                        <TouchableOpacity
                            key={idx}
                            style={[styles.monthItem, isSelected && styles.monthItemSelected]}
                            onPress={() => toggleMonth(idx)}
                        >
                            <Text style={[styles.monthText, isSelected && styles.monthTextSelected]}>
                                {name}
                            </Text>
                            {isSelected && (
                                <View style={styles.checkIcon}>
                                    <Check size={12} color="#fff" />
                                </View>
                            )}
                        </TouchableOpacity>
                    );
                })}
            </View>

            <Text style={styles.selectionInfo}>
                Đã chọn: {selectedMonths.length} tháng
            </Text>
        </View>
    );
};

const styles = StyleSheet.create({
    container: { marginBottom: 16 },
    quickSelectRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        marginBottom: 12
    },
    quickBtn: {
        paddingHorizontal: 12,
        paddingVertical: 6,
        backgroundColor: '#f0f0f5',
        borderRadius: 8
    },
    quickBtnText: { fontSize: 12, color: Colors.primary, fontWeight: '600' },
    quarterRow: {
        flexDirection: 'row',
        justifyContent: 'space-around',
        marginBottom: 12
    },
    quarterBtn: {
        width: 50,
        height: 28,
        backgroundColor: Colors.primary + '20',
        borderRadius: 14,
        justifyContent: 'center',
        alignItems: 'center'
    },
    quarterText: { fontSize: 12, color: Colors.primary, fontWeight: 'bold' },
    monthGrid: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        justifyContent: 'space-between'
    },
    monthItem: {
        width: '32%',
        paddingVertical: 12,
        backgroundColor: '#f5f5f7',
        borderRadius: 10,
        alignItems: 'center',
        marginBottom: 8,
        position: 'relative'
    },
    monthItemSelected: {
        backgroundColor: Colors.primary,
    },
    monthText: { fontSize: 13, color: Colors.text },
    monthTextSelected: { color: '#fff', fontWeight: 'bold' },
    checkIcon: {
        position: 'absolute',
        top: 4,
        right: 4,
        width: 16,
        height: 16,
        borderRadius: 8,
        backgroundColor: Colors.success,
        justifyContent: 'center',
        alignItems: 'center'
    },
    selectionInfo: {
        textAlign: 'center',
        fontSize: 12,
        color: Colors.textSecondary,
        marginTop: 8
    }
});

export default MonthSelector;
