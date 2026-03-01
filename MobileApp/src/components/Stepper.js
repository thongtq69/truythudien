import React from 'react';
import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import { Minus, Plus } from 'lucide-react-native';
import { Colors } from '../theme/colors';

const Stepper = ({ value, onValueChange, min = 0, max = 20, label = "" }) => {
    const decrement = () => {
        if (value > min) onValueChange(value - 1);
    };

    const increment = () => {
        if (value < max) onValueChange(value + 1);
    };

    return (
        <View style={styles.container}>
            {label ? <Text style={styles.label}>{label}</Text> : null}
            <View style={styles.stepperContainer}>
                <Text style={styles.valueText}>{value === 0 ? "Không kê khai" : `${value} hộ`}</Text>
                <View style={styles.controls}>
                    <TouchableOpacity
                        onPress={decrement}
                        style={[styles.button, value <= min && styles.buttonDisabled]}
                        disabled={value <= min}
                    >
                        <Minus size={18} color={value <= min ? Colors.textSecondary : Colors.text} />
                    </TouchableOpacity>
                    <View style={styles.divider} />
                    <TouchableOpacity
                        onPress={increment}
                        style={[styles.button, value >= max && styles.buttonDisabled]}
                        disabled={value >= max}
                    >
                        <Plus size={18} color={value >= max ? Colors.textSecondary : Colors.text} />
                    </TouchableOpacity>
                </View>
            </View>
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
    },
    label: {
        fontSize: 12,
        color: Colors.textSecondary,
        marginBottom: 4,
    },
    stepperContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        backgroundColor: Colors.light,
        borderRadius: 8,
        paddingHorizontal: 8,
        height: 36,
    },
    valueText: {
        fontSize: 14,
        fontWeight: '500',
    },
    controls: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    button: {
        padding: 4,
    },
    buttonDisabled: {
        opacity: 0.3,
    },
    divider: {
        width: 1,
        height: 20,
        backgroundColor: Colors.border,
        marginHorizontal: 8,
    },
});

export default Stepper;
