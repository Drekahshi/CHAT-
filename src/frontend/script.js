// ===== MOCK DATA =====
let mockNFTs = [
    { 
        id: 1, 
        name: 'Pharaoh Mask', 
        desc: 'Ancient Egyptian relic', 
        price: '2.5 ETH', 
        chain: 'eth', 
        image: 'https://images.unsplash.com/photo-1578303512597-81e6cc155b3e?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        owner: 'marketplace',
        chatPrice: 250,
        views: '1.2K',
        likes: 234,
        collection: 'Ancient Artifacts',
        verified: true
    },
    { 
        id: 2, 
        name: 'Ming Vase', 
        desc: 'Classic Chinese artifact', 
        price: '1.8 MATIC', 
        chain: 'poly', 
        image: 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        owner: 'marketplace',
        chatPrice: 180,
        views: '3.5K',
        likes: 567,
        collection: 'Asian Heritage',
        verified: true
    },
    { 
        id: 3, 
        name: 'Viking Shield', 
        desc: 'Norse heritage piece', 
        price: '3.2 HBAR', 
        chain: 'hedera', 
        image: 'https://images.unsplash.com/photo-1587734195503-904fca47e0e9?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        owner: 'marketplace',
        chatPrice: 320,
        views: '2.1K',
        likes: 389,
        collection: 'European History',
        verified: true
    },
    { 
        id: 4, 
        name: 'Aztec Calendar', 
        desc: 'Mesoamerican treasure', 
        price: '2.1 ETH', 
        chain: 'eth', 
        image: 'https://images.unsplash.com/photo-1541535650810-10d26f5c2ab3?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        owner: 'marketplace',
        chatPrice: 210,
        views: '4.2K',
        likes: 612,
        collection: 'Ancient Artifacts',
        verified: true
    },
    { 
        id: 5, 
        name: 'Indian Taj Model', 
        desc: 'Mughal architectural NFT', 
        price: '1.5 MATIC', 
        chain: 'poly', 
        image: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        owner: 'marketplace',
        chatPrice: 150,
        views: '892',
        likes: 145,
        collection: 'Asian Heritage',
        verified: false
    },
    { 
        id: 6, 
        name: 'African Mask', 
        desc: 'West African tribal art', 
        price: '2.8 HBAR', 
        chain: 'hedera', 
        image: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80',
        owner: 'marketplace',
        chatPrice: 280,
        views: '5.8K',
        likes: 934,
        collection: 'African Culture',
        verified: true
    }
];

const mockStats = [
    { label: 'Total Volume', value: '2.4M HBAR', change: '+12.5% this month' },
    { label: 'Cultural Collections', value: '1,234', change: '+89 new this week' },
    { label: 'Total Heritage NFTs', value: '456,789', change: '+15K minted today' },
    { label: 'Active Users', value: '45,678', change: '+2.3% growth' }
];

const mockRewards = [
    { icon: '💰', title: '$CHAT Discounts', desc: '20% off on all cultural purchases' },
    { icon: '🎁', title: 'Exclusive Drops', desc: 'Early access to new heritage artifacts' },
    { icon: '🏆', title: 'Collector Badges', desc: 'Earn special cultural heritage badges' },
    { icon: '💎', title: 'Premium Features', desc: 'Unlock advanced cultural analytics' }
];

// ===== USER STATE =====
let userState = {
    isConnected: false,
    walletAddress: null,
    chatBalance: 0,
    maxChatBalance: 1000,
    interactions: {
        dailyLogin: false,
        exploreViewed: false,
        collectionViewed: false,
        tokenomicsViewed: false,
        rewardsViewed: false
    }
};

// ===== DOM ELEMENTS =====
const walletBtn = document.getElementById('walletBtn');
const sidebar = document.getElementById('sidebar');
const nftGrid = document.getElementById('nftGrid');
const collectionGrid = document.getElementById('collectionGrid');
const statsGrid = document.getElementById('statsGrid');
const rewardsGrid = document.getElementById('rewardsGrid');
const toast = document.getElementById('toast');
const filterToggle = document.getElementById('filterToggle');
const filterSidebar = document.getElementById('filterSidebar');
const searchInput = document.getElementById('searchInput');

// ===== INITIALIZE =====
document.addEventListener('DOMContentLoaded', () => {
    renderNFTs();
    renderCollection();
    renderStats();
    renderRewards();
    setupEventListeners();
    updateUI();
    
    // Check for daily login bonus
    checkDailyLogin();
});

// ===== SETUP EVENT LISTENERS =====
function setupEventListeners() {
    // Image upload preview
    const nftImageInput = document.getElementById('nftImage');
    const imagePreview = document.getElementById('imagePreview');
    const previewImg = document.getElementById('previewImg');
    
    nftImageInput.addEventListener('change', function() {
        const file = this.files[0];
        if (file) {
            const reader = new FileReader();
            
            reader.addEventListener('load', function() {
                previewImg.src = reader.result;
                imagePreview.style.display = 'block';
            });
            
            reader.readAsDataURL(file);
        }
    });

    // Filter toggle (only attach if the element exists — header filter button was removed)
    if (filterToggle) {
        filterToggle.addEventListener('click', () => {
            if (filterSidebar) filterSidebar.classList.toggle('active');
        });
    }

    // Navigation links
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', (e) => {
            const href = link.getAttribute('href');
            const isHashLink = href && href.startsWith('#');

            if (isHashLink) {
                e.preventDefault();
                document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
                link.classList.add('active');

                const target = document.querySelector(href);
                if (target) {
                    target.scrollIntoView({ behavior: 'smooth' });
                }
            } else {
                // For external/internal pages (e.g., index2.html), allow default navigation
                document.querySelectorAll('.nav-link').forEach(l => l.classList.remove('active'));
                link.classList.add('active');
            }
        });
    });

    // Search functionality
    searchInput.addEventListener('input', (e) => {
        const query = e.target.value.toLowerCase();
        const filtered = mockNFTs.filter(nft =>
            (nft.name.toLowerCase().includes(query) ||
            nft.desc.toLowerCase().includes(query) ||
            nft.collection.toLowerCase().includes(query)) &&
            nft.owner === 'marketplace'
        );
        
        renderFilteredNFTs(filtered);
    });

    // Intersection Observer for section views
    setupIntersectionObserver();
}

// ===== RENDER FUNCTIONS =====
function renderNFTs() {
    const marketplaceNFTs = mockNFTs.filter(nft => nft.owner === 'marketplace');
    nftGrid.innerHTML = marketplaceNFTs.map(nft => createNFTCard(nft)).join('');
}

function renderFilteredNFTs(filteredNFTs) {
    if (filteredNFTs.length === 0) {
        nftGrid.innerHTML = `
            <div style="grid-column: 1 / -1; text-align: center; padding: 4rem;">
                <div style="font-size: 4rem; margin-bottom: 1rem;">🔍</div>
                <h3 style="color: var(--text-secondary); margin-bottom: 1rem;">No cultural artifacts found</h3>
                <p style="color: var(--text-secondary);">Try a different search term</p>
            </div>
        `;
    } else {
        nftGrid.innerHTML = filteredNFTs.map(nft => createNFTCard(nft)).join('');
    }
}

function createNFTCard(nft) {
    const badge = nft.verified ? '<div class="nft-badge"><i class="fas fa-certificate"></i> Verified</div>' : '';
    
    return `
        <div class="nft-card" data-chain="${nft.chain}">
            <div class="nft-image">
                <img src="${nft.image}" alt="${nft.name}">
                ${badge}
            </div>
            <div class="nft-details">
                <h3>${nft.name}</h3>
                <p class="collection">From ${nft.collection}</p>
                <div class="nft-stats">
                    <span>
                        <i class="fas fa-eye"></i> ${nft.views} Views
                    </span>
                    <span>
                        <i class="fas fa-heart"></i> ${nft.likes} Likes
                    </span>
                </div>
                <div class="nft-price">
                    <div>
                        <p class="label">Current Price</p>
                        <p class="price">${nft.price}</p>
                    </div>
                    <button class="buy-btn" onclick="buyNFT(${nft.id}, 'crypto')">
                        <i class="fas fa-shopping-cart"></i> Buy Now
                    </button>
                </div>
            </div>
        </div>
    `;
}

function renderCollection() {
    const userNFTs = mockNFTs.filter(nft => nft.owner === 'user');
    if (userNFTs.length === 0) {
        collectionGrid.innerHTML = `
            <div style="grid-column: 1 / -1; text-align: center; padding: 4rem;">
                <div style="font-size: 4rem; margin-bottom: 1rem;">🖼️</div>
                <h3 style="color: var(--text-secondary); margin-bottom: 1rem;">Your cultural collection is empty</h3>
                <p style="color: var(--text-secondary); margin-bottom: 2rem;">Start building your cultural heritage collection</p>
                <button class="connect-wallet" onclick="openModal('forge')">
                    <i class="fas fa-plus"></i> Create Your First NFT
                </button>
            </div>
        `;
    } else {
        collectionGrid.innerHTML = userNFTs.map(nft => createNFTCard(nft)).join('');
    }
}

function renderStats() {
    statsGrid.innerHTML = mockStats.map(stat => `
        <div class="stat-card">
            <h3>${stat.label}</h3>
            <p class="stat-value">${stat.value}</p>
            <p class="stat-change">${stat.change}</p>
        </div>
    `).join('');
}

function renderRewards() {
    rewardsGrid.innerHTML = mockRewards.map(reward => `
        <div class="reward-card">
            <div class="reward-icon">${reward.icon}</div>
            <h3>${reward.title}</h3>
            <p>${reward.desc}</p>
        </div>
    `).join('');
}

// ===== INTERSECTION OBSERVER FOR SECTION VIEWS =====
function setupIntersectionObserver() {
    const sections = document.querySelectorAll('.marketplace, .stats');
    
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting && userState.isConnected) {
                const sectionId = entry.target.id;
                awardSectionView(sectionId);
            }
        });
    }, { threshold: 0.5 });
    
    sections.forEach(section => {
        observer.observe(section);
    });
}

// ===== AWARD SECTION VIEW =====
function awardSectionView(sectionId) {
    if (!userState.isConnected) return;
    
    const sectionRewards = {
        'explore': { amount: 50, key: 'exploreViewed' },
        'collection': { amount: 50, key: 'collectionViewed' },
        'tokenomics': { amount: 50, key: 'tokenomicsViewed' },
        'rewards': { amount: 50, key: 'rewardsViewed' }
    };
    
    const reward = sectionRewards[sectionId];
    if (reward && !userState.interactions[reward.key]) {
        userState.interactions[reward.key] = true;
        userState.chatBalance += reward.amount;
        updateUI();
        showToast(`🎉 +${reward.amount} CHAT for exploring ${sectionId} section!`);
        saveUserState();
    }
}

// ===== CHECK DAILY LOGIN =====
function checkDailyLogin() {
    const lastLogin = localStorage.getItem('lastChatLogin');
    const today = new Date().toDateString();
    
    if (lastLogin !== today && userState.isConnected) {
        userState.interactions.dailyLogin = true;
        userState.chatBalance += 100;
        updateUI();
        showToast('🎊 Daily login bonus! +100 CHAT');
        localStorage.setItem('lastChatLogin', today);
        saveUserState();
    }
}

// ===== MODAL FUNCTIONS =====
function openModal(type) {
    if (type === 'connect') {
        document.getElementById('walletModal').classList.add('active');
    } else if (type === 'forge') {
        document.getElementById('forgeModal').classList.add('active');
    }
}

function closeModal(type) {
    if (type === 'wallet') {
        document.getElementById('walletModal').classList.remove('active');
    } else if (type === 'forge') {
        document.getElementById('forgeModal').classList.remove('active');
        // Reset form
        document.getElementById('nftName').value = '';
        document.getElementById('nftDescription').value = '';
        document.getElementById('nftPrice').value = '';
        document.getElementById('nftImage').value = '';
        document.getElementById('imagePreview').style.display = 'none';
    }
}

// ===== WALLET CONNECTION =====
function connectWallet(provider) {
    console.log(`Connecting to ${provider}...`);
    
    // Award CHAT for wallet connection
    userState.isConnected = true;
    userState.walletAddress = '0x742d35Cc6634C0532925a3b844Bc555e4a0d73f6';
    userState.chatBalance += 100; // Connection bonus
    
    showToast(`✓ Connected to ${provider}! +100 CHAT`);
    walletBtn.innerHTML = `<i class="fas fa-wallet"></i> ${userState.chatBalance} CHAT | 0x742d...3f6`;
    walletBtn.style.background = 'linear-gradient(135deg, #00d084, #00d9d9)';
    
    updateUI();
    closeModal('wallet');
    saveUserState();
    
    // Check for daily login after connection
    checkDailyLogin();
}

// ===== CREATE NFT =====
function createNFT() {
    const name = document.getElementById('nftName').value;
    const description = document.getElementById('nftDescription').value;
    const price = document.getElementById('nftPrice').value;
    const imageInput = document.getElementById('nftImage');
    const activeChain = document.querySelector('.chain-btn.active').dataset.chain;
    
    if (!name || !description || !price || !imageInput.files[0]) {
        showToast('Please fill all fields and upload an image', 'error');
        return;
    }
    
    // Award CHAT for creating NFT
    userState.chatBalance += 50;
    
    const file = imageInput.files[0];
    const reader = new FileReader();
    
    reader.addEventListener('load', function() {
        const newNFT = {
            id: mockNFTs.length + 1,
            name: name,
            desc: description,
            price: `${price} ${getChainCurrency(activeChain)}`,
            chain: activeChain,
            image: reader.result,
            owner: 'user',
            chatPrice: Math.floor(parseFloat(price) * 100),
            views: '0',
            likes: 0,
            collection: 'My Collection',
            verified: false
        };
        
        mockNFTs.push(newNFT);
        renderCollection();
        closeModal('forge');
        showToast(`✓ Cultural NFT "${name}" created successfully! +50 CHAT`);
        updateUI();
        saveUserState();
    });
    
    reader.readAsDataURL(file);
}

// ===== BUY NFT =====
function buyNFT(id, paymentMethod) {
    if (!userState.isConnected) {
        showToast('Please connect your wallet first', 'error');
        openModal('connect');
        return;
    }
    
    const nft = mockNFTs.find(nft => nft.id === id);
    if (nft) {
        if (paymentMethod === 'chat') {
            // Buy with CHAT tokens
            if (userState.chatBalance >= nft.chatPrice) {
                userState.chatBalance -= nft.chatPrice;
                nft.owner = 'user';
                
                // Award CHAT for buying with CHAT
                userState.chatBalance += 25;
                
                renderNFTs();
                renderCollection();
                showToast(`✓ Successfully purchased "${nft.name}" for ${nft.chatPrice} CHAT! +25 CHAT bonus`);
                updateUI();
                saveUserState();
            } else {
                showToast(`Insufficient CHAT balance. You need ${nft.chatPrice} CHAT`, 'error');
            }
        } else {
            // Buy with crypto (simulated)
            nft.owner = 'user';
            
            // Award CHAT for buying with crypto
            userState.chatBalance += 10;
            
            renderNFTs();
            renderCollection();
            showToast(`✓ Successfully purchased "${nft.name}"! +10 CHAT for crypto purchase`);
            updateUI();
            saveUserState();
        }
    }
}

// ===== UPDATE UI =====
function updateUI() {
    // Update wallet button
    if (userState.isConnected) {
        walletBtn.innerHTML = `<i class="fas fa-wallet"></i> ${userState.chatBalance} CHAT | 0x742d...3f6`;
        walletBtn.style.background = 'linear-gradient(135deg, #00d084, #00d9d9)';
    } else {
        walletBtn.innerHTML = `<i class="fas fa-wallet"></i> Connect Wallet`;
        walletBtn.style.background = 'linear-gradient(135deg, var(--gold), #ffed4e)';
    }
}

// ===== HELPER FUNCTIONS =====
function getChainCurrency(chain) {
    switch(chain) {
        case 'eth': return 'ETH';
        case 'poly': return 'MATIC';
        case 'hedera': return 'HBAR';
        default: return 'ETH';
    }
}

function showToast(message, type = 'success') {
    toast.textContent = message;
    toast.className = 'toast show';
    
    if (type === 'error') {
        toast.style.background = 'linear-gradient(135deg, #ff6b6b, #ff8e8e)';
    } else {
        toast.style.background = 'linear-gradient(135deg, var(--gold), #ffed4e)';
    }
    
    setTimeout(() => {
        toast.className = 'toast';
    }, 3000);
}

// ===== SAVE/LOAD USER STATE =====
function saveUserState() {
    localStorage.setItem('chatUserState', JSON.stringify(userState));
}

function loadUserState() {
    const savedState = localStorage.getItem('chatUserState');
    if (savedState) {
        userState = JSON.parse(savedState);
        updateUI();
    }
}

// Load user state on page load
loadUserState();

// Chain toggle functionality
document.querySelectorAll('.chain-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        document.querySelectorAll('.chain-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
    });
});

// Wallet button click handler
walletBtn.addEventListener('click', () => {
    if (userState.isConnected) {
        showToast(`Wallet connected with ${userState.chatBalance} CHAT`);
    } else {
        openModal('connect');
    }
});

// Close modal on background click
document.getElementById('walletModal').addEventListener('click', function(e) {
    if (e.target === this) {
        closeModal('wallet');
    }
});
document.getElementById('forgeModal').addEventListener('click', function(e) {
    if (e.target === this) {
        closeModal('forge');
    }
});