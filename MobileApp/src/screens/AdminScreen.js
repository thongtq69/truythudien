import React, { useState, useEffect } from 'react';
import { StyleSheet, View, Text, FlatList, TextInput, TouchableOpacity, Alert, SafeAreaView, ActivityIndicator, LayoutAnimation } from 'react-native';
import { Colors } from '../theme/colors';
import api from '../api/network';
import { UserPlus, Shield, User, Users, Trash2, Key } from 'lucide-react-native';

export default function AdminScreen() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [newUsername, setNewUsername] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [newRole, setNewRole] = useState('user');

    const fetchUsers = async () => {
        try {
            const response = await api.get('/admin/users');
            LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
            setUsers(response.data);
        } catch (error) {
            console.error('Fetch users failed', error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchUsers();
    }, []);

    const handleCreateUser = async () => {
        if (!newUsername || !newPassword) {
            Alert.alert('Lỗi', 'Vui lòng nhập đầy đủ thông tin');
            return;
        }
        try {
            await api.post('/admin/users', { username: newUsername, password: newPassword, role: newRole });
            Alert.alert('Thành công', 'Đã tạo tài khoản ' + newUsername);
            setNewUsername('');
            setNewPassword('');
            setNewRole('user');
            fetchUsers();
        } catch (error) {
            Alert.alert('Lỗi', error.response?.data?.error || 'Không thể tạo người dùng');
        }
    };

    const renderItem = ({ item }) => (
        <View style={styles.userItem}>
            <View style={[styles.userIcon, { backgroundColor: item.role === 'admin' ? 'rgba(255,149,0,0.1)' : 'rgba(0,122,255,0.1)' }]}>
                {item.role === 'admin' ? <Shield size={20} color={Colors.warning} /> : <User size={20} color={Colors.primary} />}
            </View>
            <View style={styles.userInfo}>
                <Text style={styles.userName}>{item.username}</Text>
                <Text style={styles.userRole}>{item.role === 'admin' ? 'Quản trị viên' : 'Nhân viên'}</Text>
            </View>
            {item.username !== 'admin' && (
                <TouchableOpacity style={styles.deleteBtn}>
                    <Trash2 size={18} color={Colors.danger} />
                </TouchableOpacity>
            )}
        </View>
    );

    return (
        <SafeAreaView style={styles.container}>
            <View style={styles.header}>
                <Text style={styles.headerTitle}>Quản lý hệ thống</Text>
            </View>

            <ScrollView contentContainerStyle={styles.scroll}>
                <View style={styles.section}>
                    <View style={styles.sectionHeader}>
                        <UserPlus size={18} color={Colors.primary} style={{ marginRight: 8 }} />
                        <Text style={styles.sectionTitle}>Tạo tài khoản mới</Text>
                    </View>

                    <View style={styles.inputGroup}>
                        <Text style={styles.miniLabel}>Tên đăng nhập</Text>
                        <TextInput
                            style={styles.input}
                            placeholder="Ví dụ: nhanvien01"
                            value={newUsername}
                            onChangeText={setNewUsername}
                            autoCapitalize="none"
                        />
                    </View>

                    <View style={styles.inputGroup}>
                        <Text style={styles.miniLabel}>Mật khẩu</Text>
                        <View style={styles.passInputWrapper}>
                            <Key size={16} color={Colors.textSecondary} style={{ marginLeft: 12 }} />
                            <TextInput
                                style={styles.passInput}
                                placeholder="Nhập mật khẩu"
                                value={newPassword}
                                onChangeText={setNewPassword}
                                secureTextEntry
                            />
                        </View>
                    </View>

                    <Text style={styles.miniLabel}>Vai trò</Text>
                    <View style={styles.roleContainer}>
                        <TouchableOpacity
                            style={[styles.roleBtn, newRole === 'user' && styles.roleBtnActive]}
                            onPress={() => setNewRole('user')}
                        >
                            <Text style={newRole === 'user' ? styles.roleTextActive : styles.roleText}>Nhân viên</Text>
                        </TouchableOpacity>
                        <TouchableOpacity
                            style={[styles.roleBtn, newRole === 'admin' && styles.roleBtnActive, { marginLeft: 12 }]}
                            onPress={() => setNewRole('admin')}
                        >
                            <Text style={newRole === 'admin' ? styles.roleTextActive : styles.roleText}>Quản trị viên</Text>
                        </TouchableOpacity>
                    </View>

                    <TouchableOpacity style={styles.createBtn} onPress={handleCreateUser}>
                        <Text style={styles.createBtnText}>Thêm tài khoản</Text>
                    </TouchableOpacity>
                </View>

                <View style={styles.section}>
                    <View style={styles.sectionHeader}>
                        <Users size={18} color={Colors.primary} style={{ marginRight: 8 }} />
                        <Text style={styles.sectionTitle}>Danh sách người dùng</Text>
                    </View>

                    {loading ? (
                        <ActivityIndicator color={Colors.primary} style={{ padding: 20 }} />
                    ) : (
                        users.map(user => (
                            <View key={user._id}>{renderItem({ item: user })}</View>
                        ))
                    )}
                </View>
            </ScrollView>
        </SafeAreaView>
    );
}

// Reuse ScrollView to avoid ScrollView inside ScrollView for list
import { ScrollView } from 'react-native';

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
    section: { backgroundColor: Colors.white, padding: 16, borderRadius: 16, marginBottom: 16, shadowColor: '#000', shadowOpacity: 0.05, elevation: 1 },
    sectionHeader: { flexDirection: 'row', alignItems: 'center', marginBottom: 20 },
    sectionTitle: { fontSize: 16, fontWeight: 'bold' },
    inputGroup: { marginBottom: 16 },
    miniLabel: { fontSize: 11, fontWeight: '600', color: Colors.textSecondary, marginBottom: 6, textTransform: 'uppercase' },
    input: { backgroundColor: '#F5F5F7', height: 44, borderRadius: 10, paddingHorizontal: 16, fontSize: 15 },
    passInputWrapper: { flexDirection: 'row', alignItems: 'center', backgroundColor: '#F5F5F7', height: 44, borderRadius: 10 },
    passInput: { flex: 1, paddingHorizontal: 12, fontSize: 15 },
    roleContainer: { flexDirection: 'row', marginBottom: 20 },
    roleBtn: { flex: 1, padding: 12, borderRadius: 10, borderWidth: 1, borderColor: '#eee', alignItems: 'center', backgroundColor: '#fff' },
    roleBtnActive: { backgroundColor: Colors.primary, borderColor: Colors.primary },
    roleText: { color: Colors.textSecondary, fontSize: 14, fontWeight: '500' },
    roleTextActive: { color: '#fff', fontWeight: 'bold' },
    createBtn: { backgroundColor: Colors.primary, height: 48, borderRadius: 12, justifyContent: 'center', alignItems: 'center', shadowColor: Colors.primary, shadowOpacity: 0.3, shadowRadius: 5, elevation: 3 },
    createBtnText: { color: '#fff', fontWeight: 'bold', fontSize: 16 },
    userItem: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: '#f5f5f5' },
    userIcon: { width: 44, height: 44, borderRadius: 22, justifyContent: 'center', alignItems: 'center' },
    userInfo: { flex: 1, marginLeft: 16 },
    userName: { fontWeight: 'bold', fontSize: 16, color: Colors.text },
    userRole: { fontSize: 13, color: Colors.textSecondary, marginTop: 2 },
    deleteBtn: { padding: 8 },
    centered: { flex: 1, justifyContent: 'center', alignItems: 'center' }
});
